import 'package:flutter/material.dart';
import '../../../core/utils/color_utils.dart';
import '../../profile/models/user_profile.dart';

class AuraCard extends StatelessWidget {

  final UserProfile profile;

  const AuraCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {

    final auraColor = ColorUtils.hexToColor(profile.auraColorActual);
    final auraName = ColorUtils.getColorName(profile.auraColorActual);

    double progress = (profile.auraPuntos % 100) / 100;

    return Container(

      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(

        gradient: LinearGradient(
          colors: [
            auraColor.withOpacity(0.9),
            auraColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: auraColor.withOpacity(0.7),
            blurRadius: 25,
            spreadRadius: 3,
          )
        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          /// HEADER
          Row(

            children: [

              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 26,
              ),

              const SizedBox(width: 8),

              const Text(
                "Your Aura",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],

          ),

          const SizedBox(height: 20),

          /// AURA NAME
          Text(
            "$auraName Aura",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// LEVEL
          Text(
            "Level ${profile.auraNivel}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          /// PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 12),

          /// POINTS
          Text(
            "${profile.auraPuntos} Aura Points",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),

        ],

      ),

    );

  }

}