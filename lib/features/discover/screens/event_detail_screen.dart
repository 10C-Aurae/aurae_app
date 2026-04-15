import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/event.dart';
import '../../tickets/data/ticket_service.dart';
import '../../tickets/screens/ticket_detail_screen.dart';
import '../../profile/data/profile_service.dart';
import '../../../core/auth/token_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool loading = false;

  Future<void> buyTicket() async {
    setState(() => loading = true);
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('No autenticado');
      final profile = await ProfileService().getMyProfile(token);
      final ticket = await TicketService.createTicket(
        usuarioId: profile.id,
        eventoId: widget.event.id,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
    } catch (e) {
      print('ERROR BUY: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Image header ───────────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 280, width: double.infinity,
                child: (event.imagenUrl.isNotEmpty)
                    ? Image.network(event.imagenUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.surface))
                    : Container(color: AppColors.surface,
                        child: const Icon(Icons.event_rounded, size: 60, color: AppColors.faint)),
              ),
              // Dark overlay gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.bg, AppColors.bg.withOpacity(0.2), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Evento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),

                  const SizedBox(height: 12),

                  Text(event.nombre,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),

                  const SizedBox(height: 10),

                  Text(event.descripcion,
                      style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5)),

                  const Spacer(),

                  // Price / info bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.muted, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(event.ubicacionNombre,
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gradient buy button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: loading ? null : AppColors.brandGradient,
                        color: loading ? AppColors.faint : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: loading ? [] : [
                          BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : buyTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.confirmation_number_rounded, color: Colors.white),
                        label: Text(loading ? 'Procesando...' : 'Obtener Ticket',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
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
}