import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../core/config/env.dart';

enum _ScanState { idle, scanning, processing, ok, alreadyUsed, error }

class StaffScanQRScreen extends StatefulWidget {
  final String standId;
  final String eventoId;
  final String token;

  const StaffScanQRScreen({
    super.key,
    required this.standId,
    required this.eventoId,
    required this.token,
  });

  @override
  State<StaffScanQRScreen> createState() => _StaffScanQRScreenState();
}

class _StaffScanQRScreenState extends State<StaffScanQRScreen> {
  final MobileScannerController _scanner = MobileScannerController();

  _ScanState _state = _ScanState.idle;
  Map<String, dynamic>? _result;
  String? _errorMsg;
  int _okCount = 0;
  int _dupCount = 0;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state == _ScanState.scanning) {
      final code = capture.barcodes.firstOrNull?.rawValue;
      if (code == null) return;
      setState(() => _state = _ScanState.processing);

      try {
        final response = await http.post(
          Uri.parse('${Env.baseUrl}/api/v1/tickets/validar-qr'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode({
            'qr_code': code,
            'evento_id': widget.eventoId,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode == 200) {
          if (data['ya_usado'] == true) {
            setState(() { _result = data; _state = _ScanState.alreadyUsed; _dupCount++; });
          } else {
            setState(() { _result = data; _state = _ScanState.ok; _okCount++; });
          }
        } else {
          throw Exception(data['detail'] ?? 'QR inválido o no reconocido.');
        }
      } catch (e) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _state = _ScanState.error;
        });
      }
    }
  }

  void _restart() => setState(() {
    _state = _ScanState.scanning;
    _result = null;
    _errorMsg = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Validar Tickets',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.muted),
            onPressed: () => _scanner.toggleTorch(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            // ── Session counters ───────────────────────────
            Row(
              children: [
                Expanded(child: _CountCard(label: 'Validados', count: _okCount, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _CountCard(label: 'Duplicados', count: _dupCount, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _buildStateContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {

      case _ScanState.idle:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.qr_code_rounded, size: 40, color: AppColors.faint),
              ),
              const SizedBox(height: 16),
              const Text('Listo para escanear',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text('Activa la cámara y apunta al QR del ticket.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => setState(() => _state = _ScanState.scanning),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Activar cámara',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );

      case _ScanState.scanning:
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(controller: _scanner, onDetect: _onDetect),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Apunta al código QR del ticket…',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _state = _ScanState.idle),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
            ),
          ],
        );

      case _ScanState.processing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Validando ticket…', style: TextStyle(color: AppColors.muted)),
            ],
          ),
        );

      case _ScanState.ok:
        return _ResultCard(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: '¡Acceso permitido!',
          titleColor: Colors.green,
          subtitle: _result?['nombre_asistente'] ?? '',
          badge: _result?['tipo'] != null ? 'Ticket ${_result!['tipo']}' : null,
          actionLabel: 'Siguiente ticket',
          actionColor: AppColors.primary,
          onAction: _restart,
        );

      case _ScanState.alreadyUsed:
        final fechaUso = _result?['fecha_uso'];
        String? fechaStr;
        if (fechaUso != null) {
          final dt = DateTime.tryParse(fechaUso);
          if (dt != null) {
            const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
            fechaStr = 'Usado el ${dt.day} ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
          }
        }
        return _ResultCard(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          title: 'Ticket ya usado',
          titleColor: Colors.orange,
          subtitle: _result?['nombre_asistente'] ?? '',
          badge: fechaStr,
          actionLabel: 'Escanear otro',
          actionColor: Colors.orange,
          onAction: _restart,
        );

      case _ScanState.error:
        return _ResultCard(
          icon: Icons.cancel_rounded,
          iconColor: AppColors.primary,
          title: 'QR inválido',
          titleColor: AppColors.primary,
          subtitle: _errorMsg ?? 'Error desconocido',
          actionLabel: 'Intentar de nuevo',
          actionColor: AppColors.primary,
          onAction: _restart,
        );
    }
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String subtitle;
  final String? badge;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  const _ResultCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    this.badge,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.12),
              border: Border.all(color: iconColor.withOpacity(0.35), width: 2),
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
          if (badge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
