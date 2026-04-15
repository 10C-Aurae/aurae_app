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

  // Arquetipos — espejo exacto de Registro.jsx en la PWA (12 arquetipos)
  static const _archetypes = [
    {'nombre': 'Techie',         'categorias': ['tecnologia', 'innovacion', 'gaming', 'ciencia']},
    {'nombre': 'Creativo',       'categorias': ['arte', 'musica', 'fotografia', 'cine', 'teatro', 'danza']},
    {'nombre': 'Networker',      'categorias': ['networking', 'negocios', 'innovacion', 'podcasts', 'educacion']},
    {'nombre': 'Gourmet',        'categorias': ['gastronomia', 'sustentabilidad', 'viajes', 'bienestar']},
    {'nombre': 'Atleta',         'categorias': ['deportes', 'bienestar', 'danza', 'sustentabilidad']},
    {'nombre': 'Estratega',      'categorias': ['negocios', 'gaming', 'networking', 'finanzas']},
    {'nombre': 'Eco-consciente', 'categorias': ['sustentabilidad', 'gastronomia', 'deportes', 'bienestar', 'ciencia']},
    {'nombre': 'Artista',        'categorias': ['arte', 'musica', 'teatro', 'danza', 'fotografia', 'cine', 'literatura']},
    {'nombre': 'Viajero',        'categorias': ['viajes', 'gastronomia', 'fotografia', 'literatura', 'sustentabilidad']},
    {'nombre': 'Pensador',       'categorias': ['literatura', 'ciencia', 'educacion', 'podcasts', 'cine']},
    {'nombre': 'Trendsetter',    'categorias': ['moda', 'arte', 'fotografia', 'musica', 'gaming']},
    {'nombre': 'Explorador',     'categorias': <String>[]},
  ];

  static String? _inferArchetype(List<String> userInterests) {
    if (userInterests.isEmpty) return 'Explorador';
    final norm = userInterests.map((i) => i.toLowerCase().trim()).toSet();

    Map<String, dynamic>? best;
    int bestScore = 0;

    for (final arch in _archetypes) {
      final cats = List<String>.from(arch['categorias'] as List);
      if (cats.isEmpty) continue;
      final score = cats.where((c) => norm.contains(c)).length;
      if (score > bestScore) {
        bestScore = score;
        best = arch;
      }
    }
    return bestScore > 0 ? best!['nombre'] as String : 'Explorador';
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