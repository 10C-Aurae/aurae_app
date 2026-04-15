import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/config/env.dart';
import '../../../core/auth/token_service.dart';
import '../../profile/models/order.dart';

class OrderService {
  static const String _base = '${Env.baseUrl}/api/v1';

  // ── Listar órdenes del usuario ──────────────────────────────
  static Future<List<Order>> getOrdersByUserId(String userId, String token) async {
    final response = await ApiClient.get('/ordenes/usuario/$userId', token);
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('Error loading orders');
  }

  // ── Crear orden ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> crearOrden({
    required String usuarioId,
    required String eventoId,
    required double montoTotal,
    String moneda = 'MXN',
    String tipo = 'general',
  }) async {
    final token = await TokenService().getToken();
    if (token == null) throw Exception('Sin sesión');

    final res = await http.post(
      Uri.parse('$_base/ordenes/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'usuario_id': usuarioId,
        'evento_id': eventoId,
        'monto_total': montoTotal,
        'moneda': moneda,
        'items': [{'tipo': tipo, 'precio_unitario': montoTotal == 0 ? 0 : montoTotal / 1.1, 'cantidad': 1}],
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception((jsonDecode(res.body) as Map)['detail'] ?? 'Error al crear orden');
  }

  // ── Iniciar pago (Stripe PaymentIntent) ────────────────────
  /// Returns { client_secret, orden_id, monto_total, ... }
  static Future<Map<String, dynamic>> iniciarPago(String ordenId) async {
    final token = await TokenService().getToken();
    if (token == null) throw Exception('Sin sesión');

    final res = await http.post(
      Uri.parse('$_base/ordenes/$ordenId/pagar'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception((jsonDecode(res.body) as Map)['detail'] ?? 'Error al iniciar pago');
  }
}
