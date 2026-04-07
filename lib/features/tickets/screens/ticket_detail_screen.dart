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

              /// 🔥 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
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
              ),

              const SizedBox(height: 20),

              /// 🔥 CARD PRINCIPAL
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

                      /// 🔹 INFO + QR
                      Column(
                        children: [

                          /// EVENTO
                          Text(
                            "Evento ID",
                            style: TextStyle(color: Colors.grey[600]),
                          ),

                          Text(
                            ticket.eventoId,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text("Tipo: ${ticket.tipo}"),

                          const SizedBox(height: 20),

                          /// 🔥 QR
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[100],
                            ),
                            child: QrImageView(
                              data: ticket.qrCode,
                              size: 220,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// ID
                          Text(
                            "ID: ${ticket.id}",
                            style: const TextStyle(fontSize: 12),
                          ),

                          const SizedBox(height: 15),

                          /// STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ticket.statusUso.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// 🔥 BOTONES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          /// USAR
                          ElevatedButton(
                            onPressed: (!isActive || loading)
                                ? null
                                : useTicket,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Usar"),
                          ),

                          /// CANCELAR
                          ElevatedButton(
                            onPressed: (!isActive || loading)
                                ? null
                                : cancelTicket,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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

  /// 🔥 USAR TICKET
  Future<void> useTicket() async {

    setState(() => loading = true);

    try {

      await TicketService.useTicket(widget.ticket.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket usado")),
      );

      Navigator.pop(context);

    } catch (e) {

      print("ERROR USE TICKET: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al usar ticket")),
      );

    } finally {
      setState(() => loading = false);
    }
  }

  /// 🔥 CANCELAR TICKET
  Future<void> cancelTicket() async {

    setState(() => loading = true);

    try {

      await TicketService.cancelTicket(widget.ticket.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket cancelado")),
      );

      Navigator.pop(context);

    } catch (e) {

      print("ERROR CANCEL TICKET: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cancelar ticket")),
      );

    } finally {
      setState(() => loading = false);
    }
  }
}