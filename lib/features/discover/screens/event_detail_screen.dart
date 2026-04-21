import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/event.dart';
import '../../tickets/screens/buy_ticket_screen.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/data/profile_service.dart';
import '../../tickets/data/ticket_service.dart';
import '../data/stands_service.dart';
import '../widgets/stand_card.dart';
import '../../concierge/screens/concierge_screen.dart';
import '../../aura_flow/screens/aura_flow_screen.dart';
import '../../scan_qr/screens/scan_qr_v2_screen.dart';
import 'bluetooth_test_screen.dart';
import '../../chat/screens/event_chat_screen.dart';
import '../widgets/chatbot_evento.dart';
import '../../../core/bluetooth/bluetooth_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool hasTicket = false;
  bool checkingTicket = true;

  StreamSubscription? _bleSub;
  BluetoothStatus? _bleStatus;

  @override
  void initState() {
    super.initState();
    _loadStands();
    _checkTicketOwnership();
    _bleSub = BluetoothService().statusStream.listen((event) {
      if (!mounted) return;
      final status = event['status'];
      if (status is BluetoothStatus) setState(() => _bleStatus = status);
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    BluetoothService().stopScanning();
    super.dispose();
  }

  bool get _isScanning =>
      _bleStatus == BluetoothStatus.scanning ||
      _bleStatus == BluetoothStatus.detected ||
      _bleStatus == BluetoothStatus.handshakeSuccess;

  Future<void> _checkTicketOwnership() async {
    try {
      final token = await TokenService().getToken();
      
      if (token == null) {
        if (mounted) setState(() => checkingTicket = false);
        return;
      }

      final user = await ProfileService().getMyProfile(token);
      final tickets = await TicketService.getMyTickets(user.id);
      
      final ownsTicket = tickets.any((t) => t.eventoId == widget.event.id && t.statusUso != 'cancelado');
      
      if (mounted) {
        setState(() {
          hasTicket = ownsTicket;
          checkingTicket = false;
        });
        
        if (hasTicket) {
          final ble = BluetoothService();
          ble.setEventoId(widget.event.id);
          // Safety check for web or unsupported devices
          ble.startScanning().catchError((e) => print("Bluetooth Scan Error: $e"));
        }
      }
    } catch (e) {
      print("Error checking ticket: $e");
      if (mounted) setState(() => checkingTicket = false);
    }
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
      floatingActionButton: ChatbotEvento(
        eventoId: event.id,
        eventoNombre: event.nombre,
      ),
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
                      _buildMetaItem(
                        Icons.calendar_today_rounded, formattedStart, 'Inicio',
                        onTap: () => _addToCalendar(event),
                      ),
                      _buildMetaItem(
                        Icons.timer_rounded, formattedEnd, 'Fin',
                      ),
                      _buildMetaItem(
                        Icons.place_rounded, event.ubicacionNombre, 'Ubicación',
                        onTap: () => _openMaps(event.ubicacionNombre),
                      ),
                      _buildMetaItem(
                        Icons.people_alt_rounded,
                        (event.capacidadMax == null || event.capacidadMax == 0) ? 'Ilimitada' : '${event.capacidadMax}',
                        'Capacidad',
                      ),
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

                  // ── Digital Handshake card (siempre visible) ────────
                  _buildHandshakeCard(event),
                  const SizedBox(height: 24),

                  // ── Stands + herramientas: solo con ticket ─────────
                  if (!checkingTicket && hasTicket) ...[
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
                        builder: (_) => ScanQRV2Screen(eventoId: event.id),
                      )),
                    ),
                    _buildToolTile(
                      Icons.chat_bubble_outline_rounded, 'Chat del evento', 'Habla con otros asistentes',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EventChatScreen(eventoId: event.id, eventoNombre: event.nombre),
                      )),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  // Gradient buy button
                  if (checkingTicket)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (hasTicket)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ya tienes un ticket para este evento. Búscalo en Mis Tickets.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                          label: const Text('Ya tienes tu ticket',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ),
                    )
                  else
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

  void _addToCalendar(Event event) {
    final title = Uri.encodeComponent(event.nombre);
    final location = Uri.encodeComponent(event.ubicacionNombre);

    // Android: intent to calendar; iOS: calshow scheme
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=$title'
      '&dates=${_fmtGcal(event.fechaInicio)}/${_fmtGcal(event.fechaFin)}'
      '&location=$location',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _fmtGcal(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year.toString().padLeft(4,'0')}'
           '${u.month.toString().padLeft(2,'0')}'
           '${u.day.toString().padLeft(2,'0')}'
           'T${u.hour.toString().padLeft(2,'0')}'
           '${u.minute.toString().padLeft(2,'0')}00Z';
  }

  void _openMaps(String location) {
    final q = Uri.encodeComponent(location);
    launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _buildMetaItem(IconData icon, String text, String label, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onTap != null ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
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
          if (onTap != null)
            const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.primary),
        ],
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: content);
    return content;
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

  // ── Digital Handshake card ──────────────────────────────────────────────
  //
  // Visible siempre para que el feature sea descubrible. El estado depende de
  // si el usuario tiene ticket y de si el scanner BLE está corriendo.
  Widget _buildHandshakeCard(Event event) {
    final ready      = !checkingTicket && hasTicket;
    final scanning   = ready && _isScanning;

    final String subtitle;
    if (checkingTicket) {
      subtitle = 'Verificando tu acceso…';
    } else if (!hasTicket) {
      subtitle = 'Disponible con tu ticket del evento';
    } else if (scanning) {
      subtitle = 'Detectando stands cercanos…';
    } else {
      subtitle = 'Toca para ver los stands cerca de ti';
    }

    final Color accent = ready ? AppColors.primary : AppColors.muted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: scanning ? 0.45 : 0.2), width: scanning ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ready
            ? () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BluetoothTestScreen(eventName: event.nombre, eventoId: event.id),
                ))
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Necesitas un ticket para activar el Digital Handshake.')),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _HandshakePulse(active: scanning, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Digital Handshake',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ready ? AppColors.ink : AppColors.muted,
                            )),
                        if (scanning) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('ACTIVO',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: accent, letterSpacing: 1)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(
                ready ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: AppColors.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ícono de Bluetooth con ondas animadas cuando el scanner está activo.
class _HandshakePulse extends StatefulWidget {
  final bool active;
  final Color color;
  const _HandshakePulse({required this.active, required this.color});

  @override
  State<_HandshakePulse> createState() => _HandshakePulseState();
}

class _HandshakePulseState extends State<_HandshakePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _HandshakePulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active) ...[
            AnimatedBuilder(animation: _ctrl, builder: (_, _) => _ring(_ctrl.value)),
            AnimatedBuilder(animation: _ctrl, builder: (_, _) => _ring((_ctrl.value + 0.5) % 1.0)),
          ],
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: widget.active ? 0.2 : 0.08),
            ),
            child: Icon(
              widget.active ? Icons.bluetooth_searching_rounded : Icons.bluetooth_rounded,
              size: 18,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t) {
    final size = 36 + (18 * t);
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.22 * (1 - t)),
        ),
      ),
    );
  }
}