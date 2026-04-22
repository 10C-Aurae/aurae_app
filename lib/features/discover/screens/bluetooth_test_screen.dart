import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import '../../../theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/bluetooth/bluetooth_service.dart';

class BluetoothTestScreen extends StatefulWidget {
  final String eventName;
  final String eventoId;
  const BluetoothTestScreen({super.key, required this.eventName, required this.eventoId});

  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> with SingleTickerProviderStateMixin {
  final BluetoothService _ble = BluetoothService();
  late AnimationController _radarController;
  StreamSubscription? _subscription;
  StreamSubscription? _debugSub;

  Map<String, dynamic>? _lastStatus;
  final Map<String, dynamic> _nearbyStands = {};

  // Debug mode: lista todos los dispositivos BLE detectados (filtrados o no).
  bool _debugMode = false;
  final Map<String, ScanResult> _allDevices = {};

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _subscription = _ble.statusStream.listen((event) {
      if (!mounted) return;
      setState(() {
        _lastStatus = event;
        if (event.containsKey('standId')) {
          _nearbyStands[event['standId']] = event;
        }
      });
      if (event['status'] == BluetoothStatus.awaitingConfirmation) {
        final standId = event['standId'] as String?;
        if (standId != null) _maybeShowConfirmation(standId);
      }
    });

    _debugSub = _ble.debugScanStream.listen((result) {
      if (!mounted) return;
      setState(() {
        _allDevices[result.device.remoteId.toString()] = result;
      });
    });

    // Start scanning if not already running (e.g. screen opened without going through EventDetailScreen)
    if (!_ble.isScanning) {
      _ble.setEventoId(widget.eventoId);
      _ble.startScanning();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debugSub?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowConfirmation(String standId) async {
    if (!_ble.tryClaimConfirmation(standId)) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Visitaste este stand?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink)),
        content: Text(
          'Detectamos el stand $standId cerca de ti durante los últimos minutos. ¿Lo registramos?',
          style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, aún no', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sí, registrar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        await _ble.confirmarHandshake(standId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green.shade700, content: const Text('Visita registrada')),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar la visita.')),
        );
      }
    } else {
      _ble.descartarHandshake(standId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _lastStatus?['status'];
    final statusMsg = status == BluetoothStatus.permissionDenied
        ? 'Permisos de Bluetooth denegados. Actívalos en Ajustes.'
        : (_lastStatus?['message'] ?? 'Iniciando escaneo...');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Digital Handshake', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _debugMode ? 'Ocultar debug BLE' : 'Ver debug BLE',
            icon: Icon(_debugMode ? Icons.bug_report_rounded : Icons.bug_report_outlined,
                color: _debugMode ? AppColors.primary : AppColors.muted),
            onPressed: () => setState(() => _debugMode = !_debugMode),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Radar Visualization
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRadarCircles(),
                RotationTransition(
                  turns: _radarController,
                  child: _buildRadarSweep(),
                ),
                Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 48,
                  color: status == BluetoothStatus.permissionDenied ? AppColors.muted : AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Status Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    statusMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  if (status == BluetoothStatus.handshakeSuccess) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('¡Registrado con éxito!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  if (status == BluetoothStatus.permissionDenied) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Abrir Ajustes', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Listado
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.nav.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_debugMode ? 'DEBUG · TODOS LOS BLE (${_allDevices.length})' : 'STANDS CERCANOS',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 1.2)),
                        if (_debugMode)
                          Text('${_allDevices.values.where((d) => d.advertisementData.serviceUuids.isNotEmpty).length} c/ UUID',
                              style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _debugMode ? _buildDebugList() : _buildStandsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandsList() {
    if (_nearbyStands.isEmpty) {
      return const Center(child: Text('Buscando dispositivos...', style: TextStyle(color: AppColors.faint, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _nearbyStands.length,
      itemBuilder: (context, index) => _buildStandTile(_nearbyStands.values.elementAt(index)),
    );
  }

  Widget _buildDebugList() {
    if (_allDevices.isEmpty) {
      return const Center(child: Text('Aún no se detectan dispositivos BLE.', style: TextStyle(color: AppColors.faint, fontSize: 13)));
    }
    final items = _allDevices.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildDebugTile(items[i]),
    );
  }

  Widget _buildDebugTile(ScanResult r) {
    final name = r.device.platformName.isEmpty ? r.advertisementData.advName : r.device.platformName;
    final uuids = r.advertisementData.serviceUuids.map((g) => g.toString().toLowerCase()).toList();
    final hasAurae = uuids.any((u) => u.replaceAll('-', '').startsWith('ae7ae000'));
    final msdKeys = r.advertisementData.manufacturerData.keys.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasAurae ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name.isEmpty ? '(sin nombre)' : name,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: hasAurae ? AppColors.primary : AppColors.ink,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text('${r.rssi} dBm', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(r.device.remoteId.toString(),
              style: const TextStyle(fontSize: 10, color: AppColors.faint, fontFamily: 'monospace')),
          if (uuids.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('UUIDs: ${uuids.join(", ")}',
                style: TextStyle(fontSize: 10, color: hasAurae ? AppColors.primary : AppColors.muted, fontFamily: 'monospace'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (msdKeys.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('MSD: ${msdKeys.map((k) => '0x${k.toRadixString(16)}').join(", ")}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted, fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarCircles() {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        final radius = (index + 1) * 60.0;
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15 - (index * 0.05))),
          ),
        );
      }),
    );
  }

  Widget _buildRadarSweep() {
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.0),
            AppColors.primary.withValues(alpha: 0.5),
          ],
          stops: const [0.75, 1.0],
        ),
      ),
    );
  }

  Widget _buildStandTile(Map<String, dynamic> data) {
    final double? progress = (data['progress'] as num?)?.toDouble();
    final int rssi = (data['rssi'] as int?) ?? -100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(
              Icons.pin_drop_rounded,
              size: 20,
              color: (progress != null && progress >= 1.0) ? Colors.green : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['standId'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Intensidad: $rssi dBm', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surface,
                      color: progress >= 1.0 ? Colors.green : AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (progress != null && progress >= 1.0)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
