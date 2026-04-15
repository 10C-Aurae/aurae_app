import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AuraDisplay extends StatelessWidget {
  final Color auraColor;
  final String nombre;

  const AuraDisplay({super.key, required this.auraColor, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Outer glow container
        Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: auraColor.withOpacity(0.45), blurRadius: 80, spreadRadius: 12),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  auraColor,
                  auraColor.withOpacity(0.60),
                  auraColor.withOpacity(0.15),
                ],
              ),
              border: Border.all(color: auraColor.withOpacity(0.35), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome, size: 52, color: Colors.white),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          nombre,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),

        const SizedBox(height: 4),

        Text(
          'Tu aura está activa',
          style: TextStyle(fontSize: 13, color: auraColor.withOpacity(0.85)),
        ),
      ],
    );
  }
}