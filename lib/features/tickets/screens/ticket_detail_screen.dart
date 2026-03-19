import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/auth/token_service.dart';
import '../data/ticket_service.dart';
import '../models/ticket.dart';

class TicketDetailScreen extends StatefulWidget {

  final Ticket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {

  bool loading = false;

  @override
  Widget build(BuildContext context) {

    final ticket = widget.ticket;
    final isActive = ticket.statusUso == "activo";

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: Column(
            children: [

              /// HEADER
              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const Text(
                    "Ticket",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// CARD
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                      )
                    ],
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        children: [

                          Text(
                            ticket.eventoId,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text("Tipo: ${ticket.tipo}"),

                          const SizedBox(height: 20),

                          /// QR
                          QrImageView(
                            data: ticket.qrCode,
                            size: 220,
                          ),

                          const SizedBox(height: 20),

                          Text("ID: ${ticket.id}"),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ticket.statusUso.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      /// BOTONES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          ElevatedButton(
                            onPressed: loading ? null : useTicket,
                            child: const Text("Usar"),
                          ),

                          ElevatedButton(
                            onPressed: loading ? null : cancelTicket,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Cancelar"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> useTicket() async {

    setState(() => loading = true);

    final token = await TokenService().getToken();
    if (token == null) return;

    await TicketService().useTicket(token, widget.ticket.id);

    Navigator.pop(context);
  }

  Future<void> cancelTicket() async {

    setState(() => loading = true);

    final token = await TokenService().getToken();
    if (token == null) return;

    await TicketService().cancelTicket(token, widget.ticket.id);

    Navigator.pop(context);
  }
}