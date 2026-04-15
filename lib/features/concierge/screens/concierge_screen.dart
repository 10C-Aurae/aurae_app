import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../data/cola_service.dart';
import '../models/cola_virtual.dart';

class ConciergeScreen extends StatefulWidget {
  /// Optional: only show turns for this event
  final String? eventoId;
  final String? eventoNombre;

  const ConciergeScreen({super.key, this.eventoId, this.eventoNombre});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final ColaService _service = ColaService();

  List<ColaVirtual> _turnos = [];
  bool _loading = true;
  String? _error;
  final Set<String> _confirmando = {};
  final Set<String> _cancelando = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 10 s to detect status changes pushed by staff
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('Sin sesión');
      final all = await _service.misTurnos(token);
      // Keep only active turns (not atendido/cancelado); optionally filter by event
      final active = all.where((t) =>
        t.status != EstadoCola.atendido &&
        t.status != EstadoCola.cancelado &&
        (widget.eventoId == null || t.eventoId == widget.eventoId),
      ).toList();
      if (mounted) setState(() { _turnos = active; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _confirmar(ColaVirtual turno) async {
    setState(() => _confirmando.add(turno.id));
    try {
      final token = await TokenService().getToken();
      if (token == null) return;
      final updated = await _service.confirmarLlegada(token, turno.id);
      if (mounted) {
        setState(() {
          final i = _turnos.indexWhere((t) => t.id == turno.id);
          if (i >= 0) _turnos[i] = updated;
        });
      }
    } catch (e) {
      if (mounted) _showError('No se pudo confirmar: $e');
    } finally {
      if (mounted) setState(() => _confirmando.remove(turno.id));
    }
  }

  Future<void> _cancelar(ColaVirtual turno) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cancelar turno', style: TextStyle(color: AppColors.ink)),
        content: Text('¿Salir de la cola de ${turno.standNombre ?? "este stand"}?',
            style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelando.add(turno.id));
    try {
      final token = await TokenService().getToken();
      if (token == null) return;
      await _service.cancelarTurno(token, turno.id);
      if (mounted) setState(() => _turnos.removeWhere((t) => t.id == turno.id));
    } catch (e) {
      if (mounted) _showError('Error cancelando: $e');
    } finally {
      if (mounted) setState(() => _cancelando.remove(turno.id));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.eventoNombre != null ? 'Concierge · ${widget.eventoNombre}' : 'Mis turnos',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _turnos.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.card,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _turnos.length,
                        itemBuilder: (context, i) => _TurnoCard(
                          turno: _turnos[i],
                          confirmando: _confirmando.contains(_turnos[i].id),
                          cancelando: _cancelando.contains(_turnos[i].id),
                          onConfirmar: () => _confirmar(_turnos[i]),
                          onCancelar: () => _cancelar(_turnos[i]),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
            child: const Icon(Icons.queue_rounded, size: 36, color: AppColors.faint),
          ),
          const SizedBox(height: 16),
          const Text('Sin turnos activos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('Únete a la cola de un stand desde\nla pantalla del evento',
              style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Single turn card ────────────────────────────────────────────
class _TurnoCard extends StatefulWidget {
  final ColaVirtual turno;
  final bool confirmando;
  final bool cancelando;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const _TurnoCard({
    required this.turno,
    required this.confirmando,
    required this.cancelando,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  State<_TurnoCard> createState() => _TurnoCardState();
}

class _TurnoCardState extends State<_TurnoCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.turno;
    final isActivo     = t.status == EstadoCola.activo;
    final isConfirmado = t.status == EstadoCola.confirmado;
    final isEsperando  = t.status == EstadoCola.esperando;

    Color borderColor = AppColors.border;
    if (isActivo)     borderColor = AppColors.primary;
    if (isConfirmado) borderColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isActivo ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── "Es tu turno" banner ───────────────────────────
          if (isActivo)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08 + 0.10 * _pulse.value),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 16,
                        color: AppColors.primary.withOpacity(0.6 + 0.4 * _pulse.value)),
                    const SizedBox(width: 8),
                    const Text('¡Es tu turno!',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),

          if (isConfirmado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0A2318),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Llegaste ✓ · El staff te atenderá enseguida',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),

          // ── Card body ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.standNombre ?? 'Stand',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                    ),
                    _StatusBadge(status: t.status),
                  ],
                ),

                if (t.eventoNombre != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 13, color: AppColors.faint),
                      const SizedBox(width: 4),
                      Text(t.eventoNombre!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],

                if (isEsperando && t.posicionEnCola != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Text('Posición en cola: ${t.posicionEnCola}',
                            style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Actions ───────────────────────────────────
                Row(
                  children: [
                    if (isActivo) ...[
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: widget.confirmando ? null : const LinearGradient(
                                colors: [Colors.green, Color(0xFF1A9E5C)],
                              ),
                              color: widget.confirmando ? AppColors.faint : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: widget.confirmando ? null : widget.onConfirmar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: widget.confirmando
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.place_rounded, size: 16, color: Colors.white),
                              label: const Text('Ya llegué', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: widget.cancelando ? null : widget.onCancelar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: widget.cancelando
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color color;

    switch (status) {
      case EstadoCola.esperando:
        label = 'En espera'; color = Colors.orange;
        break;
      case EstadoCola.activo:
        label = 'Tu turno'; color = AppColors.primary;
        break;
      case EstadoCola.confirmado:
        label = 'Llegaste ✓'; color = Colors.green;
        break;
      default:
        label = status; color = AppColors.muted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
