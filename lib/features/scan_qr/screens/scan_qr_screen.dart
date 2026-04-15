import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';

class ScanQRScreen extends StatefulWidget {
  /// Optional: pre-filter which stand the QR belongs to (validation hint)
  final String? eventoId;

  const ScanQRScreen({super.key, this.eventoId});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController _scanner = MobileScannerController();

  bool _scanning = true;
  bool _processing = false;
  String? _resultMsg;
  bool _resultOk = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() { _scanning = false; _processing = true; });

    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('Sin sesión');

      // QR codes in Aurae encode a standId directly or a JSON payload
      String? standId;
      try {
        final decoded = jsonDecode(code) as Map<String, dynamic>;
        standId = decoded['stand_id'] as String?;
      } catch (_) {
        // Plain stand ID
        standId = code;
      }

      if (standId == null || standId.isEmpty) throw Exception('QR inválido');

      if (widget.eventoId == null || widget.eventoId!.isEmpty) {
        throw Exception('No se proporcionó el ID del evento');
      }

      final now = DateTime.now().toUtc();
      final fin = now.add(const Duration(seconds: 31));

      // Decode user ID from the JWT `sub` claim without a network call.
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Token inválido.');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      final usuarioId = claims['sub'] as String?;
      if (usuarioId == null || usuarioId.isEmpty) throw Exception('No se pudo obtener el usuario.');

      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/v1/interacciones/handshake'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario_id':       usuarioId,
          'evento_id':        widget.eventoId,
          'stand_id':         standId,
          'tipo':             'stand_visit',
          'timestamp_inicio': now.toIso8601String(),
          'timestamp_fin':    fin.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() { _resultMsg = '¡Check-in exitoso!'; _resultOk = true; _processing = false; });
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Error en el servidor');
      }
    } catch (e) {
      setState(() { _resultMsg = e.toString(); _resultOk = false; _processing = false; });
    }
  }

  void _reset() {
    setState(() { _scanning = true; _resultMsg = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Escanear QR', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
      body: Stack(
        children: [
          // ── Camera ──────────────────────────────────────────
          if (_scanning || _processing)
            MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
            ),

          // ── Scanner overlay ─────────────────────────────────
          if (_scanning)
            Center(
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Stack(
                  children: [
                    Positioned(top: 0, left: 0, child: _Corner(topLeft: true)),
                    Positioned(top: 0, right: 0, child: _Corner(topRight: true)),
                    Positioned(bottom: 0, left: 0, child: _Corner(bottomLeft: true)),
                    Positioned(bottom: 0, right: 0, child: _Corner(bottomRight: true)),
                  ],
                ),
              ),
            ),

          if (_scanning)
            Positioned(
              bottom: 60,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Apunta al QR del stand',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),

          // ── Processing ──────────────────────────────────────
          if (_processing)
            Container(
              color: AppColors.bg.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Verificando...', style: TextStyle(color: AppColors.ink, fontSize: 15)),
                  ],
                ),
              ),
            ),

          // ── Result ──────────────────────────────────────────
          if (_resultMsg != null)
            Container(
              color: AppColors.bg,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_resultOk ? Colors.green : AppColors.primary).withOpacity(0.12),
                          border: Border.all(
                            color: _resultOk ? Colors.green : AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _resultOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          size: 40,
                          color: _resultOk ? Colors.green : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _resultOk ? '¡Check-in exitoso!' : 'Error',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: _resultOk ? Colors.green : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _resultMsg!,
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: const Text('Volver', style: TextStyle(color: AppColors.muted)),
                            ),
                          ),
                          if (!_resultOk) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _reset,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                          if (_resultOk) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _reset,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Escanear otro', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Corner decoration ──────────────────────────────────────────
class _Corner extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          bottom: bottomLeft || bottomRight ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          left: topLeft || bottomLeft ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          right: topRight || bottomRight ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
