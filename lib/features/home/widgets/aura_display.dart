import 'package:flutter/material.dart';

class AuraDisplay extends StatelessWidget {
  final Color auraColor;
  final String nombre;

  const AuraDisplay({
    super.key,
    required this.auraColor,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// 🔥 AURA GRANDE
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                auraColor.withOpacity(0.9),
                auraColor.withOpacity(0.4),
                auraColor.withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: auraColor.withOpacity(0.6),
                blurRadius: 60,
                spreadRadius: 10,
              )
            ],
          ),
          child: const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
        ),

        const SizedBox(height: 20),

        Text(
          nombre,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}