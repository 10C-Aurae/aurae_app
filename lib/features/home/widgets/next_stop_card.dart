import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class NextStopCard extends StatelessWidget {
  const NextStopCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text('Siguiente parada',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Stand de Tecnología',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),

          const SizedBox(height: 4),

          const Text(
            'Recomendado según tu aura',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Gradient accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}