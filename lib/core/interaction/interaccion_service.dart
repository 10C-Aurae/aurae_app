import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/token_service.dart';
import '../config/env.dart';
import '../api/api_client.dart';

class InteraccionService {
  final TokenService _tokenService = TokenService();

  Future<void> registrarHandshake({
    required String standId,
    required String eventoId,
    String tipo = 'stand_visit',
  }) async {
    final token = await _tokenService.getToken();
    if (token == null) throw Exception('Sin sesión activa');

    // Extraer usuario_id del token (JWT sub claim)
    final usuarioId = _extractUserIdFromToken(token);
    if (usuarioId == null) throw Exception('No se pudo identificar al usuario');

    final now = DateTime.now().toUtc();
    final fin = now.add(const Duration(seconds: 31)); // Duración mínima por defecto

    final response = await ApiClient.post(
      '/interacciones/handshake/',
      token,
      {
        'usuario_id': usuarioId,
        'evento_id': eventoId,
        'stand_id': standId,
        'tipo': tipo,
        'timestamp_inicio': now.toIso8601String(),
        'timestamp_fin': fin.toIso8601String(),
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Error al registrar interacción');
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
