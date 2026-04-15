import 'package:flutter/material.dart';

class Archetype {
  final String id;
  final String nombre;
  final IconData iconData; // we'll use mapped icons in the UI

  Archetype(this.id, this.nombre, this.iconData);
}

class UserProfile {

  final String id;
  final String nombre;
  final String email;
  final String avatarUrl;
  final int auraPuntos;
  final String auraColorActual;
  final int auraNivel;
  final List<String> intereses;
  final String? arquetipoNombre;

  UserProfile({
    required this.id,
    required this.nombre,
    required this.email,
    required this.avatarUrl,
    required this.auraPuntos,
    required this.auraColorActual,
    required this.auraNivel,
    required this.intereses,
    this.arquetipoNombre,
  });

  // Archetypes logic from PWA
  static const _archetypes = [
    {'id': 'techie', 'nombre': 'Explorador Tecnológico', 'categorias': ['tecnologia', 'innovacion']},
    {'id': 'foodie', 'nombre': 'Maestro Gastronómico', 'categorias': ['gastronomia']},
    {'id': 'networker', 'nombre': 'Networking Master', 'categorias': ['negocios', 'networking']},
    {'id': 'artista', 'nombre': 'Alma Creativa', 'categorias': ['arte', 'musica']},
    {'id': 'gamer', 'nombre': 'Espíritu Gamer', 'categorias': ['gaming']},
    {'id': 'eco', 'nombre': 'Guardián Verde', 'categorias': ['sustentabilidad']},
  ];

  static String? _inferArchetype(List<String> userInterests) {
    if (userInterests.isEmpty) return null;
    final interestsNorm = userInterests.map((i) => i.toLowerCase().trim()).toList();
    
    Map<String, dynamic>? bestArch;
    int bestScore = 0;

    for (final arch in _archetypes) {
      final categories = List<String>.from(arch['categorias'] as List);
      final score = categories.where((cat) => interestsNorm.contains(cat.toLowerCase())).length;
      if (score > bestScore) {
        bestScore = score;
        bestArch = arch;
      }
    }
    return bestArch?['nombre'] as String?;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {

    return UserProfile(
      id: json["id"],
      nombre: json["nombre"],
      email: json["email"],
      avatarUrl: json["avatar_url"] ?? "",
      auraPuntos: json["aura_puntos"] ?? 0,
      auraColorActual: json["aura_color_actual"] ?? "#000000",
      auraNivel: json["aura_nivel"] ?? 1,
      intereses: List<String>.from(json["vector_intereses"] ?? []),
    );

  }

}