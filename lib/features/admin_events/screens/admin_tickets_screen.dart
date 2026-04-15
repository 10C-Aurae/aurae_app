import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/models/ticket.dart';
import '../../tickets/data/ticket_service.dart';

class AdminTicketsScreen extends StatefulWidget {
  final String eventId;
  final String eventNombre;

  const AdminTicketsScreen({super.key, required this.eventId, required this.eventNombre});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  List<Ticket> tickets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => loading = true);
    try {
      tickets = await TicketService.getTicketsByEvent(widget.eventId);
    } catch (e) {
      debugPrint('Error loading admin tickets: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markUsed(String ticketId) async {
    try {
      await TicketService.useTicket(ticketId);
      _loadTickets();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tickets del Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.eventNombre, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        color: AppColors.primary,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : tickets.isEmpty
                ? const Center(child: Text('No hay tickets vendidos aún', style: TextStyle(color: AppColors.muted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final t = tickets[index];
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.id, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontFamily: 'monospace')),
                                  const SizedBox(height: 4),
                                  Text(t.statusUso.toUpperCase(), 
                                    style: TextStyle(
                                      color: t.statusUso == 'activo' ? Colors.greenAccent : AppColors.faint, 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Tipo: ${t.tipo}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (t.statusUso == 'activo')
                              ElevatedButton(
                                onPressed: () => _markUsed(t.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Validar', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
