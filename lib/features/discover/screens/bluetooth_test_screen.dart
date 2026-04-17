import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';
import '../../../core/bluetooth/bluetooth_service.dart';

class BluetoothTestScreen extends StatefulWidget {
  final String eventName;
  const BluetoothTestScreen({super.key, required this.eventName});

  @override
  State<BluetoothTestScreen> createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> with SingleTickerProviderStateMixin {
  final BluetoothService _ble = BluetoothService();
  late AnimationController _radarController;
  
  Map<String, dynamic>? _lastStatus;
  final Map<String, dynamic> _nearbyStands = {};

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _ble.statusStream.listen((event) {
      if (mounted) {
        setState(() {
          _lastStatus = event;
          if (event.containsKey('standId')) {
            _nearbyStands[event['standId']] = event;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Prueba de Handshake', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                const Icon(Icons.bluetooth_searching_rounded, size: 48, color: AppColors.primary),
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
                  BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _lastStatus?['message'] ?? 'Iniciando escaneo...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  if (_lastStatus?['status'] == BluetoothStatus.handshakeSuccess) ...[
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
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Detected Stands List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.nav.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(28, 24, 28, 12),
                    child: Text('STANDS CERCANOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 1.2)),
                  ),
                  Expanded(
                    child: _nearbyStands.isEmpty 
                      ? const Center(child: Text('Buscando dispositivos...', style: TextStyle(color: AppColors.faint, fontSize: 13)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _nearbyStands.length,
                          itemBuilder: (context, index) {
                            final stand = _nearbyStands.values.elementAt(index);
                            return _buildStandTile(stand);
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
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
            border: Border.all(color: AppColors.primary.withOpacity(0.15 - (index * 0.05))),
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
            AppColors.primary.withOpacity(0.0),
            AppColors.primary.withOpacity(0.5),
          ],
          stops: const [0.75, 1.0],
        ),
      ),
    );
  }

  Widget _buildStandTile(Map<String, dynamic> data) {
    final double? progress = data['progress'];
    final int rssi = data['rssi'] ?? -100;
    
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
            child: Icon(Icons.pin_drop_rounded, size: 20, color: progress != null && progress >= 1.0 ? Colors.green : AppColors.primary),
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
