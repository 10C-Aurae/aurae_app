class StandChatMessage {
  final String id;
  final String? usuarioId;
  final String? nombreUsuario;
  final bool esStaff;
  final String texto;
  final DateTime createdAt;

  StandChatMessage({
    required this.id,
    this.usuarioId,
    this.nombreUsuario,
    required this.esStaff,
    required this.texto,
    required this.createdAt,
  });

  factory StandChatMessage.fromJson(Map<String, dynamic> json) {
    return StandChatMessage(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'],
      nombreUsuario: json['nombre_usuario'],
      esStaff: json['es_staff'] == true,
      texto: json['texto'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
