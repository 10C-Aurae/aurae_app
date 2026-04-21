import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';
import 'staff_scan_qr_screen.dart';
import 'staff_chat_screen.dart';
import 'staff_beacon_screen.dart';

class StaffQueueScreen extends StatefulWidget {
  final Map<String, dynamic> stand;
  final String token;

  const StaffQueueScreen({super.key, required this.stand, required this.token});

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  Map<String, dynamic>? _estado;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  DateTime? _lastRefresh;
  Timer? _timer;

  String get _standId => widget.stand['id'] ?? '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetch(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/v1/colas/stand/$_standId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        if (mounted) setState(() {
          _estado = jsonDecode(response.body) as Map<String, dynamic>;
          _loading = false;
          _lastRefresh = DateTime.now();
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _llamar() async {
    setState(() => _actionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/v1/colas/stand/$_standId/llamar'),
        headers: _headers,
      );
      if (response.statusCode != 200) throw Exception('Error al llamar siguiente');
      await _fetch(silent: true);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _marcarAtendido(String colaId) async {
    setState(() => _actionLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/v1/colas/$colaId/atendido?stand_id=$_standId'),
        headers: _headers,
      );
      if (response.statusCode != 200) throw Exception('Error al marcar atendido');
      await _fetch(silent: true);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _logout() async {
    await TokenService().deleteToken();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standNombre = widget.stand['nombre'] ?? 'Stand';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Panel de cola', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(standNombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sensors_rounded, color: AppColors.primary),
            tooltip: 'Beacon del stand',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StaffBeaconScreen(
                standId: _standId,
                standNombre: widget.stand['nombre'] ?? 'Stand',
                token: widget.token,
              ),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            tooltip: 'Pedidos y mensajes',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StaffChatScreen(
                standId: _standId,
                standNombre: widget.stand['nombre'] ?? 'Stand',
                token: widget.token,
              ),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Validar tickets',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StaffScanQRScreen(
                standId: _standId,
                eventoId: widget.stand['evento_id'] ?? '',
                token: widget.token,
              ),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: _actionLoading ? null : _fetch,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.muted),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetch, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final estado = _estado!;
    final enAtencion = estado['en_atencion'] as Map<String, dynamic>?;
    final enCola = (estado['usuarios_en_cola'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalEsperando = estado['total_esperando'] ?? 0;
    final tiempoEspera = estado['tiempo_espera_min'] ?? 0;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [

          // ── Currently serving ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EN ATENCIÓN AHORA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: AppColors.muted, letterSpacing: 1)),
                const SizedBox(height: 12),
                if (enAtencion != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          child: const Center(child: Text('👤', style: TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Turno #${enAtencion['posicion']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                      color: AppColors.primary, letterSpacing: 0.5)),
                              if (enAtencion['servicio_nombre'] != null)
                                Text(enAtencion['servicio_nombre'],
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _actionLoading ? null : () => _marcarAtendido(enAtencion['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _actionLoading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('Marcar como Atendido',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Nadie en atención',
                          style: TextStyle(color: AppColors.faint, fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Queue ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('EN FILA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: AppColors.muted, letterSpacing: 1)),
                    Row(
                      children: [
                        Text('$totalEsperando',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                                color: AppColors.ink)),
                        const SizedBox(width: 4),
                        Text('(~$tiempoEspera min)',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_actionLoading || totalEsperando == 0) ? null : _llamar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _actionLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('📣  Llamar Siguiente',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                if (enCola.isEmpty)
                  const Center(child: Text('La fila está vacía',
                      style: TextStyle(color: AppColors.faint, fontSize: 14)))
                else
                  ...enCola.map((u) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text('#${u['posicion']}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                          if (u['servicio_nombre'] != null) ...[
                            const SizedBox(width: 8),
                            Text(u['servicio_nombre'],
                                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ]),
                        Text('~${u['tiempo_espera_min']} min',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  )),
              ],
            ),
          ),

          if (_lastRefresh != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Actualizado ${_lastRefresh!.hour.toString().padLeft(2, '0')}:'
                '${_lastRefresh!.minute.toString().padLeft(2, '0')} · auto cada 10s',
                style: const TextStyle(fontSize: 11, color: AppColors.faint),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
