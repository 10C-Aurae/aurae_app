import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../interaction/interaccion_service.dart';

enum BluetoothStatus { idle, scanning, detected, handshakeSuccess, exit }

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final InteraccionService _interaccionService = InteraccionService();
  
  String? _eventoId;
  bool _isScanning = false;
  
  // Stream for UI feedback
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // Track first detection time for each standId
  final Map<String, DateTime> _detectedStands = {};
  // Track already registered handshakes to avoid duplicates in one session
  final Set<String> _registeredHandshakes = {};

  // Track last seen time for each standId
  final Map<String, DateTime> _lastSeen = {};
  // Thresholds
  static const int rssiThreshold = -70; // Adjust based on calibration
  static const Duration permanenceRequired = Duration(minutes: 2);
  static const Duration exitThreshold = Duration(seconds: 30);
  static const Duration scanInterval = Duration(seconds: 10);

  StreamSubscription? _scanSubscription;
  Timer? _exitCheckTimer;

  void setEventoId(String id) {
    _eventoId = id;
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    if (_eventoId == null) {
      print("BluetoothService: No se puede escanear sin un eventoId");
      return;
    }

    // Check permissions/state
    if (await FlutterBluePlus.isSupported == false) {
      print("BluetoothService: El dispositivo no soporta Bluetooth");
      return;
    }

    _isScanning = true;
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        _processScanResult(r);
      }
    });

    // Start exit check timer
    _exitCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkExits());

    // Start scanning with interval for battery optimization
    _performScanCycle();
  }

  void stopScanning() {
    _isScanning = false;
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _exitCheckTimer?.cancel();
    _detectedStands.clear();
    _lastSeen.clear();
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
        print("BluetoothService Scan Error: $e");
      }
      await Future.delayed(scanInterval);
    }
  }

  void _processScanResult(ScanResult result) {
    String? standId = _extractStandId(result);
    if (standId == null) return;

    // Update last seen
    _lastSeen[standId] = DateTime.now();

    // Proximity check
    if (result.rssi < rssiThreshold) {
      return;
    }

    // Haven't registered this interaction yet?
    if (_registeredHandshakes.contains(standId)) return;

    final now = DateTime.now();
    if (!_detectedStands.containsKey(standId)) {
      _detectedStands[standId] = now;
      _statusController.add({
        'status': BluetoothStatus.detected,
        'standId': standId,
        'rssi': result.rssi,
        'message': 'Stand detectado: $standId. Mantente cerca...',
      });
      print("BluetoothService: Stand detectado: $standId. Iniciando validación...");
    } else {
      final firstDetected = _detectedStands[standId]!;
      final progress = now.difference(firstDetected).inSeconds / permanenceRequired.inSeconds;
      
      _statusController.add({
        'status': BluetoothStatus.detected,
        'standId': standId,
        'rssi': result.rssi,
        'progress': progress,
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
        print("BluetoothService: Señal perdida para $standId. Disparando evento de salida.");
        _handleExit(standId);
        toRemove.add(standId);
      }
    });

    for (var id in toRemove) {
      _lastSeen.remove(id);
      _detectedStands.remove(id);
      _registeredHandshakes.remove(id); // Allow re-interaction if they return
    }
  }

  String? _extractStandId(ScanResult result) {
    // 1. Check Service UUIDs
    if (result.advertisementData.serviceUuids.isNotEmpty) {
      return result.advertisementData.serviceUuids.first.toString();
    }
    
    // 2. Fallback to Device Name
    final name = result.device.platformName;
    if (name.startsWith("AuraeStand_")) {
      return name.replaceFirst("AuraeStand_", "");
    }

    return null;
  }

  Future<void> _handleHandshake(String standId) async {
    if (_eventoId == null) return;
    
    try {
      await _interaccionService.registrarHandshake(
        standId: standId,
        eventoId: _eventoId!,
        tipo: 'ble_handshake',
      );
      _registeredHandshakes.add(standId);
      _statusController.add({
        'status': BluetoothStatus.handshakeSuccess,
        'standId': standId,
        'message': '¡Handshake digital exitoso!',
      });
    } catch (e) {
      _statusController.add({'status': BluetoothStatus.detected, 'error': e.toString()});
      print("BluetoothService: Error handshake: $e");
    }
  }

  Future<void> _handleExit(String standId) async {
    // Logic to notify backend or UI about exit
    // Typically: /api/v1/interacciones/exit or similar
    // For now, we'll just log it.
    _statusController.add({
      'status': BluetoothStatus.exit,
      'standId': standId,
      'message': 'Has salido del área del stand.',
    });
    print("BluetoothService: Usuario salió del rango del stand: $standId");
  }
}
