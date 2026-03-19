import 'package:flutter/material.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {

  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final isActive = ticket.statusUso == "activo";

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.deepPurple, Colors.purpleAccent]
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                const Icon(
                  Icons.confirmation_number,
                  color: Colors.white,
                  size: 30,
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.statusUso.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// EVENTO
            Text(
              ticket.eventoId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Tipo: ${ticket.tipo}",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "Ver detalle",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}