class UserProfile {

  final String nombre;
  final String email;
  final String auraColor;
  final int auraPoints;
  final int auraLevel;
  final List<dynamic> interests;

  UserProfile({
    required this.nombre,
    required this.email,
    required this.auraColor,
    required this.auraPoints,
    required this.auraLevel,
    required this.interests,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {

    return UserProfile(
      nombre: json["nombre"] ?? "",
      email: json["email"] ?? "",
      auraColor: json["aura_color_actual"] ?? "#FFFFFF",
      auraPoints: json["aura_puntos"] ?? 0,
      auraLevel: json["aura_nivel"] ?? 1,
      interests: json["vector_intereses"] ?? [],
    );

  }

}