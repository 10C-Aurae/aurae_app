import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../interaction/interaccion_service.dart';

enum BluetoothStatus { idle, scanning, detected, handshakeSuccess, exit, permissionDenied }

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final InteraccionService _interaccionService = InteraccionService();

  String? _eventoId;
  bool _isScanning = false;

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  final Map<String, DateTime> _detectedStands = {};
  final Set<String> _registeredHandshakes = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, List<int>> _rssiSamples = {};

  static const int rssiThreshold = -70;
  static const Duration permanenceRequired = Duration(minutes: 2);
  static const Duration exitThreshold = Duration(seconds: 30);
  static const Duration scanInterval = Duration(seconds: 10);

  StreamSubscription? _scanSubscription;
  Timer? _exitCheckTimer;

  void setEventoId(String id) {
    _eventoId = id;
  }

  bool get isScanning => _isScanning;

  Future<void> startScanning() async {
    if (_isScanning) return;
    if (_eventoId == null) return;

    if (await FlutterBluePlus.isSupported == false) {
      _statusController.add({'status': BluetoothStatus.idle, 'message': 'Bluetooth no soportado en este dispositivo'});
      return;
    }

    if (!await _requestPermissions()) {
      _statusController.add({'status': BluetoothStatus.permissionDenied, 'message': 'Permisos de Bluetooth denegados'});
      return;
    }

    _isScanning = true;

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        _processScanResult(r);
      }
    });

    _exitCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkExits());

    _performScanCycle();
  }

  void stopScanning() {
    _isScanning = false;
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _exitCheckTimer?.cancel();
    _detectedStands.clear();
    _lastSeen.clear();
    _rssiSamples.clear();
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _performScanCycle() async {
    while (_isScanning) {
      _statusController.add({'status': BluetoothStatus.scanning, 'message': 'Buscando stands...'});
      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: true,
        );
      } catch (e) {
        _statusController.add({'status': BluetoothStatus.idle, 'error': e.toString()});
      }
      await Future.delayed(scanInterval);
    }
  }

  void _processScanResult(ScanResult result) {
    final standId = _extractStandId(result);
    if (standId == null) return;

    _lastSeen[standId] = DateTime.now();

    if (result.rssi < rssiThreshold) return;

    if (_registeredHandshakes.contains(standId)) return;

    _rssiSamples.putIfAbsent(standId, () => []).add(result.rssi);

    final now = DateTime.now();
    if (!_detectedStands.containsKey(standId)) {
      _detectedStands[standId] = now;
      _statusController.add({
        'status': BluetoothStatus.detected,
        'standId': standId,
        'rssi': result.rssi,
        'message': 'Stand detectado: $standId. Mantente cerca...',
      });
    } else {
      final firstDetected = _detectedStands[standId]!;
      final progress = now.difference(firstDetected).inSeconds / permanenceRequired.inSeconds;

      _statusController.add({
        'status': BluetoothStatus.detected,
        'standId': standId,
        'rssi': result.rssi,
        'progress': progress.clamp(0.0, 1.0),
      });

      if (now.difference(firstDetected) >= permanenceRequired) {
        _handleHandshake(standId);
      }
    }
  }

  void _checkExits() {
    final now = DateTime.now();
    final toRemove = <String>[];

    _lastSeen.forEach((standId, lastSeen) {
      if (now.difference(lastSeen) > exitThreshold) {
        _handleExit(standId);
        toRemove.add(standId);
      }
    });

    for (final id in toRemove) {
      _lastSeen.remove(id);
      _detectedStands.remove(id);
      _rssiSamples.remove(id);
      _registeredHandshakes.remove(id);
    }
  }

  // Extracts the stand MongoDB ObjectId from a scan result. Two formats:
  //   1. Device name "AuraeStand_{id}" — usado por beacons físicos con el
  //      nombre largo completo.
  //   2. Service UUID "ae7ae000-xxxx-xxxx-xxxx-xxxxxxxxxxxx" — usado cuando el
  //      encargado emite BLE desde su teléfono (el nombre no cabe en 31 bytes,
  //      así que el stand_id se codifica en los 12 bytes finales del UUID).
  String? _extractStandId(ScanResult result) {
    final name = result.device.platformName;
    if (name.startsWith("AuraeStand_")) {
      return name.replaceFirst("AuraeStand_", "");
    }
    for (final uuid in result.advertisementData.serviceUuids) {
      final hex = uuid.toString().toLowerCase().replaceAll('-', '');
      if (hex.length == 32 && hex.startsWith('ae7ae000')) {
        return hex.substring(8);
      }
    }
    return null;
  }

  Future<void> _handleHandshake(String standId) async {
    if (_eventoId == null) return;
    _registeredHandshakes.add(standId); // mark before API call to prevent duplicates

    final timestampInicio = _detectedStands[standId]!;
    final samples = _rssiSamples[standId] ?? [];
    final rssiPromedio = samples.isEmpty
        ? null
        : samples.reduce((a, b) => a + b) / samples.length;

    try {
      await _interaccionService.registrarHandshake(
        standId: standId,
        eventoId: _eventoId!,
        tipo: 'ble_handshake',
        timestampInicio: timestampInicio,
        rssiPromedio: rssiPromedio,
      );
      _statusController.add({
        'status': BluetoothStatus.handshakeSuccess,
        'standId': standId,
        'message': '¡Handshake digital exitoso!',
      });
    } catch (e) {
      _registeredHandshakes.remove(standId); // allow retry on error
      _statusController.add({'status': BluetoothStatus.detected, 'error': e.toString()});
    }
  }

  Future<void> _handleExit(String standId) async {
    _statusController.add({
      'status': BluetoothStatus.exit,
      'standId': standId,
      'message': 'Has salido del área del stand.',
    });
  }
}
