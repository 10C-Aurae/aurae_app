import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────
  static const Color bg       = Color(0xFF0C0C0C); // deep black
  static const Color surface  = Color(0xFF141414); // elevated surface
  static const Color card     = Color(0xFF1A1A1A); // card bg
  static const Color nav      = Color(0xFF0A0A0A); // navbar darker

  // ── Borders ──────────────────────────────────────
  static const Color border      = Color(0xFF272727);
  static const Color borderDark  = Color(0xFF3A3A3A);

  // ── Brand Accents ─────────────────────────────────
  static const Color primary     = Color(0xFFFF5C5C); // coral — CTA
  static const Color primaryDark = Color(0xFFE03E3E); // coral hover
  static const Color secondary   = Color(0xFF9B5DE5); // purple — creative
  static const Color accent      = Color(0xFFFF9F43); // amber — festive

  // ── Text ─────────────────────────────────────────
  static const Color ink   = Color(0xFFF0EFEF); // warm white
  static const Color muted = Color(0xFF888888); // mid gray
  static const Color faint = Color(0xFF404040); // very dim

  // ── Gradients ─────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientWarm = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
