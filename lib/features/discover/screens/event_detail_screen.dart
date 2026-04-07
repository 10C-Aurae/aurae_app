import 'package:flutter/material.dart';
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

      if (token == null) {
        throw Exception("Usuario no autenticado");
      }

      final profile = await ProfileService().getMyProfile(token);

      final ticket = await TicketService.createTicket(
        usuarioId: profile.id,
        eventoId: widget.event.id,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticket: ticket),
        ),
      );

    } catch (e) {

      print("ERROR BUY: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );

    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final event = widget.event;

    return Scaffold(
      body: Column(
        children: [

          /// 🔥 HEADER
          Stack(
            children: [

              SizedBox(
                height: 260,
                width: double.infinity,
                child: (event.imagenUrl != null && event.imagenUrl!.isNotEmpty)
                    ? Image.network(
                        event.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade300),
                      )
                    : Container(color: Colors.grey.shade300),
              ),

              SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),

          /// 🔥 BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    event.nombre,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(event.descripcion),

                  const Spacer(),

                  /// 🔥 BOTÓN PRO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(

                      onPressed: loading ? null : buyTicket,

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.confirmation_number),
                                SizedBox(width: 10),
                                Text("Obtener Ticket"),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}