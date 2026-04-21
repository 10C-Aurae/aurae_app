import 'dart:convert';
import '../auth/token_service.dart';
import '../api/api_client.dart';

class InteraccionService {
  final TokenService _tokenService = TokenService();

  Future<void> registrarHandshake({
    required String standId,
    required String eventoId,
    String tipo = 'stand_visit',
    DateTime? timestampInicio,
    double? rssiPromedio,
  }) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Sin sesión activa');

    final usuarioId = _extractUserIdFromToken(token);
    if (usuarioId == null) throw Exception('No se pudo identificar al usuario');

    final inicio = (timestampInicio ?? DateTime.now()).toUtc();
    final fin = DateTime.now().toUtc();

    final body = <String, dynamic>{
      'usuario_id': usuarioId,
      'evento_id': eventoId,
      'stand_id': standId,
      'tipo': tipo,
      'timestamp_inicio': inicio.toIso8601String(),
      'timestamp_fin': fin.toIso8601String(),
    };
    if (rssiPromedio != null) body['rssi_promedio'] = rssiPromedio;

    final response = await ApiClient.post(
      '/interacciones/handshake',
      token,
      body,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Error al registrar interacción');
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final claims = jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
