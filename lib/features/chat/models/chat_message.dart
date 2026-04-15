class ChatMessage {
  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String? arquetipo;
  final String? auraColor;
  final String texto;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    this.arquetipo,
    this.auraColor,
    required this.texto,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nombreUsuario: json['nombre_usuario'] ?? 'Anónimo',
      arquetipo: json['arquetipo'],
      auraColor: json['aura_color'],
      texto: json['texto'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
