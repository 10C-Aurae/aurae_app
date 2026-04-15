import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../theme/app_colors.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onUse;
  final VoidCallback onCancel;

  const TicketCard({super.key, required this.ticket, required this.onUse, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isActive = ticket.statusUso == 'activo';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.30) : AppColors.border),
        boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 20)] : [],
      ),
      child: Column(
        children: [
          // ── Gradient top bar ─────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: isActive ? AppColors.brandGradient : const LinearGradient(colors: [AppColors.faint, AppColors.faint]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Header row ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.primary : AppColors.faint).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.confirmation_number_rounded,
                          size: 18, color: isActive ? AppColors.primary : AppColors.faint),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ticket ${ticket.tipo}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? const Color(0xFF4ADE80) : AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(ticket.statusUso,
                                  style: TextStyle(
                                    fontSize: 12, color: isActive ? const Color(0xFF4ADE80) : AppColors.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // ── QR Code ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                  ),
                  child: QrImageView(data: ticket.qrCode, size: 130),
                ),

                const SizedBox(height: 20),

                // ── Action buttons ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: isActive ? AppColors.brandGradient : null,
                            color: isActive ? null : AppColors.faint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            onPressed: isActive ? onUse : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Usar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: isActive ? onCancel : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isActive ? const Color(0xFFFF5C5C).withOpacity(0.50) : AppColors.border),
                            foregroundColor: const Color(0xFFFF5C5C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}