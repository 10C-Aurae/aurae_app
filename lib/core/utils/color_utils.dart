import 'package:flutter/material.dart';

class ColorUtils {

  static Color hexToColor(String hex) {

    hex = hex.replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF$hex";
    }

    return Color(int.parse(hex, radix: 16));

  }

  static String getColorName(String hex) {

    hex = hex.toUpperCase();

    switch (hex) {

      case "#FFFFFF":
        return "White";

      case "#800080":
        return "Purple";

      case "#4B0082":
        return "Indigo";

      case "#0000FF":
        return "Blue";

      case "#008000":
        return "Green";

      case "#FFFF00":
        return "Yellow";

      case "#FFA500":
        return "Orange";

      case "#FF0000":
        return "Red";

      default:
        return "Aura Energy";

    }

  }

}