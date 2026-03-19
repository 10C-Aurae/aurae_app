class UserProfile {

  final String id;
  final String nombre;
  final String email;
  final String avatarUrl;
  final int auraPuntos;
  final String auraColorActual;
  final int auraNivel;
  final List<String> intereses;

  UserProfile({
    required this.id,
    required this.nombre,
    required this.email,
    required this.avatarUrl,
    required this.auraPuntos,
    required this.auraColorActual,
    required this.auraNivel,
    required this.intereses,
  });

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