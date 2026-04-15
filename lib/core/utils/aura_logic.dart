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
}
