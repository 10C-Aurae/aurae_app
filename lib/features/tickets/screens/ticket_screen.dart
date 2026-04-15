import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/data/profile_service.dart';
import '../data/ticket_service.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import '../../discover/data/event_service.dart';
import '../../notifications/widgets/notification_bell.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Ticket> tickets = [];
  bool loading = true;
  String filtro = 'todos';

  static const List<Map<String, String>> filtros = [
    {'id': 'todos', 'label': 'Todos'},
    {'id': 'activo', 'label': 'Activos'},
    {'id': 'usado', 'label': 'Usados'},
    {'id': 'cancelado', 'label': 'Cancelados'},
    {'id': 'expirado', 'label': 'Expirados'},
  ];

  @override
  void initState() {
    super.initState();
    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      final token = await TokenService().getToken();
      final user = await ProfileService().getMyProfile(token!);
      final result = await TicketService.getMyTickets(user.id);
      
      final uniqueEventIds = result.map((t) => t.eventoId).toSet();
      final Map<String, String> eventNames = {};
      final eventService = EventService();
      
      await Future.wait(uniqueEventIds.map((eid) async {
        try {
          final event = await eventService.getEventById(eid);
          eventNames[eid] = event.nombre;
        } catch (_) {}
      }));
      
      for (var t in result) {
        t.eventoNombre = eventNames[t.eventoId];
      }

      if (!mounted) return;
      setState(() { tickets = result; loading = false; });
    } catch (e) {
      print('TICKETS ERROR: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<bool> _confirmAction(BuildContext context, String title, String subtitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: const TextStyle(color: AppColors.ink)),
        content: Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: loadTickets,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.nav,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text('Mis Tickets', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              actions: const [NotificationBell()],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: AppColors.border),
              ),
            ),

            // ── Filters Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: filtros.map((f) {
                      final isSelected = filtro == f['id'];
                      return GestureDetector(
                        onTap: () => setState(() => filtro = f['id']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            f['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            if (loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              Builder(
                builder: (context) {
                  final filtered = filtro == 'todos' ? tickets : tickets.where((t) => t.statusUso == filtro).toList();

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 60, color: AppColors.faint),
                            const SizedBox(height: 14),
                            Text(filtro == 'todos' ? 'No tienes tickets aún' : 'Sin tickets "$filtro"',
                                style: const TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            const Text('Explora eventos y obtén tu primer ticket',
                                style: TextStyle(color: AppColors.faint, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ticket = filtered[index];
                          return TicketCard(
                            ticket: ticket,
                            onUse: () async {
                              final confirm = await _confirmAction(context, "¿Seguro que quieres usar este ticket?", "Esta acción validará tu entrada permanentemente.");
                              if (confirm) {
                                await TicketService.useTicket(ticket.id);
                                loadTickets();
                              }
                            },
                            onCancel: () async {
                              final confirm = await _confirmAction(context, "¿Deseas cancelar tu ticket?", "Perderás tu acceso al evento de forma irreversible.");
                              if (confirm) {
                                await TicketService.cancelTicket(ticket.id);
                                loadTickets();
                              }
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}