import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/event.dart';
import '../../tickets/screens/buy_ticket_screen.dart';


import '../data/stands_service.dart';
import '../widgets/stand_card.dart';
import '../../concierge/screens/concierge_screen.dart';
import '../../aura_flow/screens/aura_flow_screen.dart';
import '../../scan_qr/screens/scan_qr_screen.dart';
import '../../chat/screens/event_chat_screen.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final StandsService _standsService = StandsService();
  bool loading = false;
  List<dynamic> stands = [];
  bool standsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStands();
  }

  Future<void> _loadStands() async {
    try {
      final data = await _standsService.publicGetStandsByEvent(widget.event.id);
      if (mounted) setState(() => stands = data);
    } catch (e) {
      debugPrint('Error loading stands for detail: $e');
    } finally {
      if (mounted) setState(() => standsLoading = false);
    }
  }

  void buyTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyTicketScreen(event: widget.event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final String formattedStart = DateFormat('dd MMM, HH:mm').format(event.fechaInicio);
    final String formattedEnd = DateFormat('dd MMM, HH:mm').format(event.fechaFin);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Image header ───────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 320, width: double.infinity,
                  child: (event.imagenUrl.isNotEmpty)
                      ? Image.network(event.imagenUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.broken_image_rounded, size: 40, color: AppColors.faint)))
                      : Container(color: AppColors.surface,
                          child: const Icon(Icons.event_rounded, size: 60, color: AppColors.faint)),
                ),
                // Dark overlay gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.bg, AppColors.bg.withOpacity(0.0), Colors.transparent],
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
                        color: Colors.black.withOpacity(0.4),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge('Evento', AppColors.primary),
                      if (event.esGratuito) _buildBadge('Gratis', Colors.green)
                      else _buildBadge('\$${(event.precio * 1.10).toStringAsFixed(2)} MXN', Colors.orangeAccent),
                      if (event.tienePassword) _buildBadge('🔐 Con Código', Colors.blueGrey),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(event.nombre,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink)),

                  // Organizer info
                  if (event.organizadorId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text('Organizado por NESSY', // Hardcoded or fetch from ID
                            style: TextStyle(fontSize: 12, color: AppColors.muted.withOpacity(0.8), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Metadata Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildMetaItem(Icons.calendar_today_rounded, formattedStart, 'Inicio'),
                      _buildMetaItem(Icons.timer_rounded, formattedEnd, 'Fin'),
                      _buildMetaItem(Icons.place_rounded, event.ubicacionNombre, 'Ubicación'),
                      if (event.capacidadMax != null)
                        _buildMetaItem(Icons.people_alt_rounded, '${event.capacidadMax}', 'Capacidad'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(event.descripcion,
                      style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.6)),

                  // Categories
                  if (event.categorias.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      children: event.categorias.map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        backgroundColor: AppColors.card,
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Stands Section ──────────────────────────
                  if (stands.isNotEmpty || standsLoading) ...[
                    const Text('Stands del evento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      child: standsLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: stands.length,
                            itemBuilder: (context, index) => StandCard(stand: stands[index]),
                          ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Herramientas del evento ──────────────────
                  const Text('Herramientas inteligentes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.muted, letterSpacing: 0.8)),
                  const SizedBox(height: 16),
                  _buildToolTile(
                    Icons.auto_awesome_rounded, 'Concierge', 'Gestiona tus turnos virtuales',
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ConciergeScreen(eventoId: event.id, eventoNombre: event.nombre),
                    )),
                  ),
                  _buildToolTile(
                    Icons.route_rounded, 'Aura Flow', 'Tu ruta personalizada',
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AuraFlowScreen(eventoId: event.id, eventoNombre: event.nombre),
                    )),
                  ),
                  _buildToolTile(
                    Icons.qr_code_scanner_rounded, 'Escanear QR', 'Check-in manual de stands',
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ScanQRScreen(eventoId: event.id),
                    )),
                  ),
                  _buildToolTile(
                    Icons.chat_bubble_outline_rounded, 'Chat del evento', 'Habla con otros asistentes',
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EventChatScreen(eventoId: event.id, eventoNombre: event.nombre),
                    )),
                  ),

                  const SizedBox(height: 40),

                  // Gradient buy button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: loading ? null : AppColors.brandGradient,
                        color: loading ? AppColors.faint : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: loading ? [] : [
                          BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : buyTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.confirmation_number_rounded, color: Colors.white),
                        label: Text(loading ? 'Procesando...' : 'Obtener Ticket',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.bold)),
                Text(text, style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        visualDensity: VisualDensity.compact,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.muted),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
      ),
    );
  }
}