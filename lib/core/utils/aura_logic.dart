import 'dart:math';
import 'package:flutter/material.dart';

class AuraLevelInfo {
  final int nivel;
  final int min;
  final String nombre;

  const AuraLevelInfo(this.nivel, this.min, this.nombre);
}

class AuraLogic {
  static const List<AuraLevelInfo> niveles = [
    AuraLevelInfo(1, 0, 'Neutro'),
    AuraLevelInfo(2, 50, 'Despertar'),
    AuraLevelInfo(3, 150, 'Explorador'),
    AuraLevelInfo(4, 400, 'Influyente'),
    AuraLevelInfo(5, 800, 'Visionario'),
    AuraLevelInfo(6, 1500, 'Legendario'),
  ];

  static const Map<String, int> interesAHue = {
    'tecnologia': 210, 'innovacion': 210, 'tech': 210, 'digital': 210,
    'ciencia': 195, 'educacion': 195,
    'gastronomia': 25, 'comida': 25, 'food': 25, 'culinaria': 25,
    'networking': 142, 'negocios': 142, 'emprendimiento': 142, 'finanzas': 142,
    'arte': 320, 'musica': 320, 'creatividad': 320, 'diseno': 320, 'diseño': 320,
    'gaming': 270, 'juegos': 270, 'videojuegos': 270, 'esports': 270,
    'sustentabilidad': 85, 'eco': 85, 'ambiente': 85, 'naturaleza': 85,
    'deporte': 5, 'fitness': 5, 'salud': 5, 'actividad': 5,
    'moda': 340, 'fashion': 340, 'belleza': 340,
  };

  static const int defaultHue = 240;

  static const Map<int, List<double>> nivelASL = {
    1: [0, 100],
    2: [45, 78],
    3: [65, 62],
    4: [75, 50],
    5: [85, 55],
    6: [92, 48],
  };

  static Color hslToColor(double h, double s, double l) {
    return HSLColor.fromAHSL(1.0, h, s / 100.0, l / 100.0).toColor();
  }

  static double promedioHueCircular(List<int> hues) {
    if (hues.isEmpty) return defaultHue.toDouble();
    double sinSum = 0;
    double cosSum = 0;
    for (int h in hues) {
      sinSum += sin(h * pi / 180);
      cosSum += cos(h * pi / 180);
    }
    double avg = atan2(sinSum, cosSum) * 180 / pi;
    return ((avg % 360) + 360) % 360;
  }

  static Color calcularColorAura(List<String> intereses, int nivel) {
    if (nivel <= 1) return const Color(0xFFFFFFFF);

    List<int> hues = [];
    for (String i in intereses) {
      final key = i.toLowerCase().trim();
      if (interesAHue.containsKey(key)) {
        hues.add(interesAHue[key]!);
      }
    }

    final double hue = promedioHueCircular(hues);
    final sl = nivelASL[nivel] ?? [75, 50];
    
    return HSLColor.fromAHSL(1.0, hue, sl[0] / 100.0, sl[1] / 100.0).toColor();
  }

  static List<Map<String, dynamic>> getNivelesConColor(List<String> intereses) {
    return niveles.map((n) {
      final color = calcularColorAura(intereses, n.nivel);
      return {
        'nivel': n.nivel,
        'min': n.min,
        'nombre': n.nombre,
        'color': color,
      };
    }).toList();
  }

  /// Nombre del nivel dado su número (1-6).
  static String getNombreNivel(int nivel) {
    return niveles.firstWhere((n) => n.nivel == nivel, orElse: () => niveles.first).nombre;
  }

  /// Porcentaje de progreso dentro del nivel actual (0–100).
  static int getPorcentajeNivel(int puntos) {
    final sorted = [...niveles]..sort((a, b) => b.min.compareTo(a.min));
    final current = sorted.firstWhere((n) => puntos >= n.min, orElse: () => niveles.first);
    final currentIndex = niveles.indexWhere((n) => n.nivel == current.nivel);
    if (currentIndex == niveles.length - 1) return 100;
    final next = niveles[currentIndex + 1];
    final rango = next.min - current.min;
    final progreso = puntos - current.min;
    return (progreso / rango * 100).floor().clamp(0, 100);
  }

  /// Puntos que faltan para el siguiente nivel, o 0 si ya es Legendario.
  static int puntosParaSiguiente(int puntos) {
    final sorted = [...niveles]..sort((a, b) => b.min.compareTo(a.min));
    final current = sorted.firstWhere((n) => puntos >= n.min, orElse: () => niveles.first);
    final currentIndex = niveles.indexWhere((n) => n.nivel == current.nivel);
    if (currentIndex == niveles.length - 1) return 0;
    return niveles[currentIndex + 1].min - puntos;
  }

  /// Nombre del siguiente nivel, o null si ya es Legendario.
  static String? nombreSiguienteNivel(int nivel) {
    final idx = niveles.indexWhere((n) => n.nivel == nivel);
    if (idx == -1 || idx == niveles.length - 1) return null;
    return niveles[idx + 1].nombre;
  }

  // ── Arquetipos (espejo de Registro.jsx en PWA) ───────────────────────────

  static const List<Map<String, dynamic>> arquetipos = [
    {'nombre': 'Techie',         'afinidades': ['tecnologia', 'innovacion', 'gaming', 'ciencia'],                          'emoji': '⚡', 'desc': 'Explorador de lo digital y lo nuevo'},
    {'nombre': 'Creativo',       'afinidades': ['arte', 'musica', 'fotografia', 'cine', 'teatro', 'danza'],                'emoji': '🎨', 'desc': 'Tu mirada transforma el espacio'},
    {'nombre': 'Networker',      'afinidades': ['networking', 'negocios', 'innovacion', 'podcasts', 'educacion'],          'emoji': '🤝', 'desc': 'Conectas personas e ideas'},
    {'nombre': 'Gourmet',        'afinidades': ['gastronomia', 'sustentabilidad', 'viajes', 'bienestar'],                  'emoji': '🍽️', 'desc': 'Vives para experiencias con sabor'},
    {'nombre': 'Atleta',         'afinidades': ['deportes', 'bienestar', 'danza', 'sustentabilidad'],                      'emoji': '🏃', 'desc': 'Energía en movimiento'},
    {'nombre': 'Estratega',      'afinidades': ['negocios', 'gaming', 'networking', 'finanzas'],                           'emoji': '♟️', 'desc': 'Siempre tres pasos adelante'},
    {'nombre': 'Eco-consciente', 'afinidades': ['sustentabilidad', 'gastronomia', 'deportes', 'bienestar', 'ciencia'],    'emoji': '🌿', 'desc': 'El mundo importa, y lo cuidas'},
    {'nombre': 'Artista',        'afinidades': ['arte', 'musica', 'teatro', 'danza', 'fotografia', 'cine', 'literatura'], 'emoji': '🎭', 'desc': 'Sientes, creas, inspiras'},
    {'nombre': 'Viajero',        'afinidades': ['viajes', 'gastronomia', 'fotografia', 'literatura', 'sustentabilidad'],  'emoji': '✈️', 'desc': 'El mundo es tu escenario'},
    {'nombre': 'Pensador',       'afinidades': ['literatura', 'ciencia', 'educacion', 'podcasts', 'cine'],                'emoji': '📚', 'desc': 'Buscas profundidad en cada experiencia'},
    {'nombre': 'Trendsetter',    'afinidades': ['moda', 'arte', 'fotografia', 'musica', 'gaming'],                        'emoji': '✨', 'desc': 'Marcas tendencia sin proponértelo'},
    {'nombre': 'Explorador',     'afinidades': <String>[],                                                                'emoji': '🧭', 'desc': 'Curioso de todo, límite de nada'},
  ];

  // ── Etiquetas de intereses (espejo de _interestItems en register/edit screens) ─

  static const Map<String, String> _interesLabels = {
    'tecnologia':      'Tecnología',
    'musica':          'Música',
    'arte':            'Arte',
    'gaming':          'Gaming',
    'negocios':        'Negocios',
    'gastronomia':     'Gastronomía',
    'deportes':        'Deportes',
    'networking':      'Networking',
    'innovacion':      'Innovación',
    'sustentabilidad': 'Sustentabilidad',
    'fotografia':      'Fotografía',
    'moda':            'Moda',
    'cine':            'Cine',
    'viajes':          'Viajes',
    'bienestar':       'Bienestar',
    'ciencia':         'Ciencia',
    'literatura':      'Literatura',
    'danza':           'Danza',
    'podcasts':        'Podcasts',
    'educacion':       'Educación',
    'finanzas':        'Finanzas',
    'teatro':          'Teatro',
  };

  /// Devuelve la etiqueta legible del interés. Si no está en el mapa lo capitaliza.
  static String labelDeInteres(String id) {
    final key = id.toLowerCase().trim();
    if (_interesLabels.containsKey(key)) return _interesLabels[key]!;
    return key.isNotEmpty ? '${key[0].toUpperCase()}${key.substring(1)}' : id;
  }

  /// Infiere el arquetipo con más afinidades con los intereses del usuario.
  /// Devuelve 'Explorador' si no hay match.
  static Map<String, dynamic> inferirArquetipo(List<String> intereses) {
    if (intereses.isEmpty) {
      return arquetipos.last; // Explorador
    }
    final norm = intereses.map((i) => i.toLowerCase().trim()).toSet();
    Map<String, dynamic>? mejor;
    int mejorScore = 0;
    for (final a in arquetipos) {
      final afinidades = List<String>.from(a['afinidades'] as List);
      if (afinidades.isEmpty) continue;
      final score = afinidades.where((cat) => norm.contains(cat)).length;
      if (score > mejorScore) {
        mejorScore = score;
        mejor = a;
      }
    }
    return mejorScore > 0 ? mejor! : arquetipos.last;
  }
}
