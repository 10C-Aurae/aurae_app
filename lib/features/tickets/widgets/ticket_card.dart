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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          /// 🎟️ INFO
          Text(
            "Ticket ${ticket.tipo}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "Status: ${ticket.statusUso}",
            style: TextStyle(
              color: ticket.statusUso == "activo"
                  ? Colors.green
                  : Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          /// 🔳 QR
          QrImageView(
            data: ticket.qrCode,
            size: 180,
          ),

          const SizedBox(height: 20),

          /// 🔘 BOTONES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton(
                onPressed: ticket.statusUso == "activo" ? onUse : null,
                child: const Text("Usar"),
              ),

              OutlinedButton(
                onPressed: ticket.statusUso == "activo" ? onCancel : null,
                child: const Text("Cancelar"),
              ),

            ],
          )

        ],
      ),
    );
  }
}