class Ticket {
  final String id;
  final String usuarioId;
  final String eventoId;
  String? eventoNombre;
  final String tipo;
  final String statusUso;
  final String qrCode;
  final String createdAt;
  final DateTime? fechaUso;

  Ticket({
    required this.id,
    required this.usuarioId,
    required this.eventoId,
    this.eventoNombre,
    required this.tipo,
    required this.statusUso,
    required this.qrCode,
    required this.createdAt,
    this.fechaUso,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json["id"],
      usuarioId: json["usuario_id"],
      eventoId: json["evento_id"],
      tipo: json["tipo"] ?? "general",
      statusUso: json["status_uso"] ?? "pendiente",
      qrCode: json["qr_code"] ?? "",
      createdAt: json["created_at"] ?? "",
      fechaUso: json["fecha_uso"] != null ? DateTime.tryParse(json["fecha_uso"]) : null,
    );
  }
}
