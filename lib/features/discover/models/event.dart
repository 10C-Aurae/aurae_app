class Event {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final String ubicacionNombre;
  final String direccion;
  final double lat;
  final double lng;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool esGratuito;
  final double precio;
  final List<String> categorias;
  final bool activo;
  final String? organizadorId;
  final bool esPublico;
  final bool tienePassword;
  final String? passwordAcceso;
  final bool chatHabilitado;
  final String? auraFlowPrompt;
  final List<String>? arquetiposDisponibles;
  final String? infoChatbot;
  final int? capacidadMax;

  Event({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.ubicacionNombre,
    required this.direccion,
    this.lat = 0,
    this.lng = 0,
    required this.fechaInicio,
    required this.fechaFin,
    required this.esGratuito,
    required this.precio,
    required this.categorias,
    required this.activo,
    this.organizadorId,
    this.esPublico = true,
    this.tienePassword = false,
    this.passwordAcceso,
    this.chatHabilitado = true,
    this.auraFlowPrompt,
    this.arquetiposDisponibles,
    this.infoChatbot,
    this.capacidadMax,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final ubicacion = json["ubicacion"] ?? {};

    return Event(
      id: json["id"],
      nombre: json["nombre"],
      descripcion: json["descripcion"] ?? "",
      imagenUrl: json["imagen_url"] ?? "",
      ubicacionNombre: ubicacion["nombre"] ?? "",
      direccion: ubicacion["direccion"] ?? "",
      lat: (ubicacion["lat"] ?? 0).toDouble(),
      lng: (ubicacion["lng"] ?? 0).toDouble(),
      fechaInicio: DateTime.parse(json["fecha_inicio"]),
      fechaFin: DateTime.parse(json["fecha_fin"]),
      esGratuito: json["es_gratuito"] ?? true,
      precio: (json["precio"] ?? 0).toDouble(),
      categorias: List<String>.from(json["categorias"] ?? []),
      activo: json["is_active"] ?? true,
      organizadorId: json["organizador_id"],
      esPublico: json["es_publico"] ?? true,
      tienePassword: json["tiene_password"] ?? false,
      passwordAcceso: json["password_acceso"],
      chatHabilitado: json["chat_habilitado"] ?? true,
      auraFlowPrompt: json["aura_flow_prompt"],
      arquetiposDisponibles: json["arquetipos_disponibles"] != null 
          ? List<String>.from(json["arquetipos_disponibles"]) 
          : null,
      infoChatbot: json["info_chatbot"],
      capacidadMax: json["capacidad_max"],
    );
  }
}