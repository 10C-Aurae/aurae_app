class Ticket {

  final String id;
  final String eventoId;
  final String tipo;
  final String statusUso;
  final String qrCode;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.eventoId,
    required this.tipo,
    required this.statusUso,
    required this.qrCode,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json["id"],
      eventoId: json["evento_id"],
      tipo: json["tipo"],
      statusUso: json["status_uso"],
      qrCode: json["qr_code"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }
}