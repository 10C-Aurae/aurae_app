class Event {

  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final String ubicacionNombre;
  final String direccion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool esGratuito;
  final double precio;
  final List<String> categorias;
  final bool activo;

  Event({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.ubicacionNombre,
    required this.direccion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.esGratuito,
    required this.precio,
    required this.categorias,
    required this.activo,
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
      fechaInicio: DateTime.parse(json["fecha_inicio"]),
      fechaFin: DateTime.parse(json["fecha_fin"]),
      esGratuito: json["es_gratuito"] ?? true,
      precio: (json["precio"] ?? 0).toDouble(),
      categorias: List<String>.from(json["categorias"] ?? []),
      activo: json["is_active"] ?? true,
    );
  }
}