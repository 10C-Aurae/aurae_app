class AuraFlowStand {
  final String standId;
  final String nombre;
  final String descripcion;
  final String? motivo;
  final int orden;

  AuraFlowStand({
    required this.standId,
    required this.nombre,
    required this.descripcion,
    this.motivo,
    required this.orden,
  });

  factory AuraFlowStand.fromJson(Map<String, dynamic> json) {
    return AuraFlowStand(
      standId: json['stand_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      motivo: json['motivo'],
      orden: json['orden'] ?? 0,
    );
  }
}

class AuraFlowResponse {
  final String eventoId;
  final List<AuraFlowStand> recomendaciones;
  final String? mensajeIntro;
  final int totalRecomendaciones;

  AuraFlowResponse({
    required this.eventoId,
    required this.recomendaciones,
    this.mensajeIntro,
    required this.totalRecomendaciones,
  });

  factory AuraFlowResponse.fromJson(Map<String, dynamic> json) {
    final recs = (json['recomendaciones'] as List? ?? [])
        .map((r) => AuraFlowStand.fromJson(r as Map<String, dynamic>))
        .toList();
    return AuraFlowResponse(
      eventoId: json['evento_id'] ?? '',
      recomendaciones: recs,
      mensajeIntro: json['mensaje_intro'],
      totalRecomendaciones: json['total_recomendaciones'] ?? recs.length,
    );
  }
}

class AuraFlowChatMessage {
  final String role; // 'user' | 'assistant'
  final String contenido;
  final DateTime? createdAt;

  AuraFlowChatMessage({required this.role, required this.contenido, this.createdAt});

  factory AuraFlowChatMessage.fromJson(Map<String, dynamic> json) {
    return AuraFlowChatMessage(
      role: json['role'] ?? 'assistant',
      contenido: json['contenido'] ?? json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
    );
  }
}
