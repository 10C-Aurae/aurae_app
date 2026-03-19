import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileInfoCard extends StatelessWidget {

  final UserProfile profile;

  const ProfileInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {

    return Card(

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text("Nombre: ${profile.nombre}"),
            Text("Email: ${profile.email}"),
            Text("Nivel: ${profile.auraNivel}"),
            Text("Puntos: ${profile.auraPuntos}"),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: profile.intereses
                  .map((e) => Chip(label: Text(e)))
                  .toList(),
            )

          ],

        ),
      ),

    );

  }

}