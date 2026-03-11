class UserProfile {

  final String email;
  final String auraColor;
  final int points;
  final int level;

  UserProfile({
    required this.email,
    required this.auraColor,
    required this.points,
    required this.level,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {

    return UserProfile(
      email: json["email"] ?? "",
      auraColor: json["aura_color_actual"] ?? "#FFFFFF",
      points: json["aura_puntos"] ?? 0,
      level: json["aura_nivel"] ?? 1,
    );

  }

}