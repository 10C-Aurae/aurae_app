import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {

  final Ticket ticket;
  final VoidCallback onUse;
  final VoidCallback onCancel;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onUse,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {

    final isActive = ticket.statusUso == "activo";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8E85FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
          )
        ],
      ),

      child: Column(
        children: [

          Text(
            "🎟 Ticket ${ticket.tipo}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Status: ${ticket.statusUso}",
            style: TextStyle(
              color: isActive ? Colors.greenAccent : Colors.redAccent,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: ticket.qrCode,
              size: 140,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: isActive ? onUse : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Usar"),
              ),

              OutlinedButton(
                onPressed: isActive ? onCancel : null,
                child: const Text("Cancelar"),
              ),

            ],
          )
        ],
      ),
    );
  }
}