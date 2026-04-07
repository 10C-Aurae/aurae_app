class Ticket {

  final String id;
  final String usuarioId;
  final String eventoId;
  final String tipo;
  final String statusUso;
  final String qrCode;
  final String createdAt;

  Ticket({
    required this.id,
    required this.usuarioId,
    required this.eventoId,
    required this.tipo,
    required this.statusUso,
    required this.qrCode,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {

    return Ticket(
      id: json["id"],
      usuarioId: json["usuario_id"],
      eventoId: json["evento_id"],
      tipo: json["tipo"],
      statusUso: json["status_uso"],
      qrCode: json["qr_code"],
      createdAt: json["created_at"],
    );
  }
}