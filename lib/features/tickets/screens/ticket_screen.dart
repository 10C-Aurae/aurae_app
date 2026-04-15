import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/data/profile_service.dart';
import '../data/ticket_service.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Ticket> tickets = [];
  bool loading = true;

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
      setState(() { tickets = result; loading = false; });
    } catch (e) {
      print('TICKETS ERROR: $e');
      setState(() => loading = false);
    }
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: AppColors.border),
              ),
            ),
            if (loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (tickets.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 60, color: AppColors.faint),
                      SizedBox(height: 14),
                      Text('No tienes tickets aún',
                          style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500)),
                      SizedBox(height: 6),
                      Text('Explora eventos y obtén tu primer ticket',
                          style: TextStyle(color: AppColors.faint, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ticket = tickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onUse: () async {
                          await TicketService.useTicket(ticket.id);
                          loadTickets();
                        },
                        onCancel: () async {
                          await TicketService.cancelTicket(ticket.id);
                          loadTickets();
                        },
                      );
                    },
                    childCount: tickets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}