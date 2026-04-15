class NotificationModel {
  final String id;
  final String tipo;
  final String titulo;
  final String cuerpo;
  final bool leida;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.leida,
    required this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: j['id'] as String,
      tipo: j['tipo'] as String,
      titulo: j['titulo'] as String,
      cuerpo: j['cuerpo'] as String,
      leida: j['leida'] as bool,
      metadata: (j['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}
