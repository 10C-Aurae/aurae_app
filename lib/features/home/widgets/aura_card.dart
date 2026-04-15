import 'package:flutter/material.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/aura_logic.dart';
import '../../profile/models/user_profile.dart';

class AuraCard extends StatelessWidget {
  final UserProfile profile;
  const AuraCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final auraColor = ColorUtils.hexToColor(profile.auraColorActual);
    final nivelNombre = AuraLogic.getNombreNivel(profile.auraNivel);
    final siguiente = AuraLogic.nombreSiguienteNivel(profile.auraNivel);
    final porcentaje = AuraLogic.getPorcentajeNivel(profile.auraPuntos);
    final faltan = AuraLogic.puntosParaSiguiente(profile.auraPuntos);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [auraColor.withValues(alpha: 0.9), auraColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: auraColor.withValues(alpha: 0.55), blurRadius: 25, spreadRadius: 3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Tu Aura', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 16),

          // Nivel nombre
          Text(
            nivelNombre,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            'Nivel ${profile.auraNivel}  ·  ${profile.auraPuntos} puntos',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 14),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 8),

          // Texto debajo de la barra
          siguiente != null
              ? Text(
                  'Faltan $faltan pts para $siguiente',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                )
              : const Text(
                  'Nivel máximo alcanzado',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
        ],
      ),
    );
  }
}