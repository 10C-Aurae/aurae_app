import 'package:flutter/material.dart';
import '../../profile/models/user_profile.dart';

class AuraCard extends StatelessWidget {

  final UserProfile profile;

  const AuraCard({
    super.key,
    required this.profile,
  });

  Color getAuraColor(String aura) {

    switch (aura.toLowerCase()) {

      case "indigo":
        return Colors.indigo;

      case "green":
        return Colors.green;

      case "red":
        return Colors.red;

      case "blue":
        return Colors.blue;

      default:
        return Colors.purple;

    }

  }

  @override
  Widget build(BuildContext context) {

    final auraColor = getAuraColor(profile.auraColor);

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: LinearGradient(
          colors: [
            auraColor.withOpacity(0.8),
            auraColor,
          ],
        ),

        borderRadius: BorderRadius.circular(20),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "Your Aura",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            profile.auraColor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            profile.archetype,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Points: ${profile.points}",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Level: ${profile.level}",
            style: const TextStyle(
            color: Colors.white70,
            ),
          ),
        ],
      ),

    );

  }

}