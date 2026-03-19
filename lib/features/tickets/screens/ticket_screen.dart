import 'package:flutter/material.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/data/profile_service.dart';
import '../data/ticket_service.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';

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

    final token = await TokenService().getToken();

    if (token == null) {
      setMockTickets();
      return;
    }

    try {

      final profile = await ProfileService().getMyProfile(token);

      final result = await TicketService()
          .getUserTickets(token, profile.id);

      if (result.isEmpty) {
        setMockTickets();
      } else {
        setState(() {
          tickets = result;
          loading = false;
        });
      }

    } catch (e) {

      print("⚠️ BACKEND FALLÓ → usando MOCK");

      setMockTickets();
    }
  }

  /// 🔥 MOCK FALLBACK
  void setMockTickets() {
    setState(() {
      tickets = [
        Ticket(
          id: "mock123",
          eventoId: "Tech Event CDMX",
          tipo: "General",
          statusUso: "activo",
          qrCode: "MOCK_QR_123456",
          createdAt: DateTime.now(),
        ),
      ];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(

      appBar: AppBar(title: const Text("Mis Tickets")),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: tickets.length,

        itemBuilder: (context, index) {

          final ticket = tickets[index];

          return TicketCard(
            ticket: ticket,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticket: ticket),
                ),
              );
            },
          );
        },
      ),
    );
  }
}