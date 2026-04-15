class Order {
  final String id;
  final double montoTotal;
  final String moneda;
  final String status;
  final String createdAt;

  Order({
    required this.id,
    required this.montoTotal,
    required this.moneda,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      montoTotal: (json['monto_total'] ?? 0).toDouble(),
      moneda: json['moneda'] ?? 'mxn',
      status: json['status'] ?? 'pendiente',
      createdAt: json['created_at'] ?? '',
    );
  }
}
