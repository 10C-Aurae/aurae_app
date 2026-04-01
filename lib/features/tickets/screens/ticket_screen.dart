import 'package:flutter/material.dart';
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

      setState(() {
        tickets = result;
        loading = false;
      });

    } catch (e) {
      print("TICKETS ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return const Center(child: Text("No tienes tickets aún"));
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Mis Tickets"),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: loadTickets,

        child: ListView.builder(
          itemCount: tickets.length,

          itemBuilder: (context, index) {

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
        ),
      ),
    );
  }
}