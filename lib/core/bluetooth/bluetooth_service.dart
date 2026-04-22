import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../interaction/interaccion_service.dart';

enum BluetoothStatus {
  idle,
  scanning,
  detected,
  awaitingConfirmation, // permanencia cumplida, esperando confirmación del usuario
  handshakeSuccess,
  handshakeCancelled,
  exit,
  permissionDenied,
}

class PendingHandshake {
  final String standId;
  final String eventoId;
  final DateTime timestampInicio;
  final double? rssiPromedio;
  PendingHandshake({
    required this.standId,
    required this.eventoId,
    required this.timestampInicio,
    this.rssiPromedio,
  });
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final InteraccionService _interaccionService = InteraccionService();

  String? _eventoId;
  bool _isScanning = false;

  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // Stream con TODOS los scan results crudos — útil para debug porque expone
  // dispositivos BLE cercanos aunque no sean Aurae (diagnosticar advertising).
  final _debugController = StreamController<ScanResult>.broadcast();
  Stream<ScanResult> get debugScanStream => _debugController.stream;

  final Map<String, DateTime> _detectedStands = {};
  final Set<String> _registeredHandshakes = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, List<int>> _rssiSamples = {};

  // Handshakes que cumplieron permanencia y esperan confirmación del usuario.
  final Map<String, PendingHandshake> _pending = {};
  // Marca los standIds cuyo modal ya se mostró en esta sesión para evitar que
  // dos pantallas suscritas al stream abran dos dialogs al mismo tiempo.
  final Set<String> _modalShownFor = {};

  Map<String, PendingHandshake> get pendingHandshakes => Map.unmodifiable(_pending);

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
    _pending.clear();
    _modalShownFor.clear();
  }

  /// Llama esta función desde la UI antes de mostrar el modal. Devuelve true la
  /// primera vez para un standId dado; las siguientes llamadas devuelven false,
  /// evitando que dos pantallas abran el mismo dialog simultáneamente.
  bool tryClaimConfirmation(String standId) {
    if (!_pending.containsKey(standId)) return false;
    if (_modalShownFor.contains(standId)) return false;
    _modalShownFor.add(standId);
    return true;
  }

  /// El usuario aceptó: se hace el POST real y se marca como registrado.
  Future<void> confirmarHandshake(String standId) async {
    final pending = _pending.remove(standId);
    if (pending == null) return;
    _registeredHandshakes.add(standId);

    try {
      await _interaccionService.registrarHandshake(
        standId: pending.standId,
        eventoId: pending.eventoId,
        tipo: 'ble_handshake',
        timestampInicio: pending.timestampInicio,
        rssiPromedio: pending.rssiPromedio,
      );
      _statusController.add({
        'status': BluetoothStatus.handshakeSuccess,
        'standId': standId,
        'message': '¡Visita registrada!',
      });
    } catch (e) {
      // Revertir para permitir reintentar
      _registeredHandshakes.remove(standId);
      _pending[standId] = pending;
      _modalShownFor.remove(standId);
      _statusController.add({'status': BluetoothStatus.detected, 'error': e.toString()});
      rethrow;
    }
  }

  /// El usuario rechazó el registro: se descarta sin POST y no se vuelve a
  /// preguntar por ese stand en esta sesión.
  void descartarHandshake(String standId) {
    _pending.remove(standId);
    _registeredHandshakes.add(standId);
    _statusController.add({
      'status': BluetoothStatus.handshakeCancelled,
      'standId': standId,
    });
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
    _debugController.add(result);
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

  // Cumplida la permanencia: marca el stand como pendiente de confirmación y
  // notifica a la UI. El POST real se hace en `confirmarHandshake` cuando el
  // usuario acepta el modal.
  void _handleHandshake(String standId) {
    if (_eventoId == null) return;
    if (_pending.containsKey(standId) || _registeredHandshakes.contains(standId)) return;

    final timestampInicio = _detectedStands[standId]!;
    final samples = _rssiSamples[standId] ?? const <int>[];
    final rssiPromedio = samples.isEmpty
        ? null
        : samples.reduce((a, b) => a + b) / samples.length;

    _pending[standId] = PendingHandshake(
      standId: standId,
      eventoId: _eventoId!,
      timestampInicio: timestampInicio,
      rssiPromedio: rssiPromedio,
    );

    _statusController.add({
      'status': BluetoothStatus.awaitingConfirmation,
      'standId': standId,
      'message': 'Confirma tu visita al stand',
    });
  }

  Future<void> _handleExit(String standId) async {
    _statusController.add({
      'status': BluetoothStatus.exit,
      'standId': standId,
      'message': 'Has salido del área del stand.',
    });
  }
}
