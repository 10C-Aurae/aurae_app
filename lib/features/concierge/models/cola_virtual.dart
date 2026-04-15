class ColaVirtual {
  final String id;
  final String standId;
  final String? standNombre;
  final String eventoId;
  final String? eventoNombre;
  final String status;
  final int? posicionEnCola;
  final String? servicioId;
  final String? servicioNombre;
  final DateTime createdAt;

  ColaVirtual({
    required this.id,
    required this.standId,
    this.standNombre,
    required this.eventoId,
    this.eventoNombre,
    required this.status,
    this.posicionEnCola,
    this.servicioId,
    this.servicioNombre,
    required this.createdAt,
  });

  factory ColaVirtual.fromJson(Map<String, dynamic> json) {
    return ColaVirtual(
      id: json['id'] ?? '',
      standId: json['stand_id'] ?? '',
      standNombre: json['stand_nombre'],
      eventoId: json['evento_id'] ?? '',
      eventoNombre: json['evento_nombre'],
      status: json['status'] ?? 'esperando',
      posicionEnCola: json['posicion_en_cola'],
      servicioId: json['servicio_id'],
      servicioNombre: json['servicio_nombre'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  ColaVirtual copyWith({String? status, int? posicionEnCola}) {
    return ColaVirtual(
      id: id,
      standId: standId,
      standNombre: standNombre,
      eventoId: eventoId,
      eventoNombre: eventoNombre,
      status: status ?? this.status,
      posicionEnCola: posicionEnCola ?? this.posicionEnCola,
      servicioId: servicioId,
      servicioNombre: servicioNombre,
      createdAt: createdAt,
    );
  }
}

class EstadoCola {
  static const String esperando  = 'esperando';
  static const String activo     = 'activo';
  static const String confirmado = 'confirmado';
  static const String atendido   = 'atendido';
  static const String cancelado  = 'cancelado';
}
