import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../models/aura_flow_models.dart';

class AuraFlowService {
  static const String _base = '${Env.baseUrl}/api/v1/aura-flow';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<AuraFlowResponse> recomendar(String token, String eventoId) async {
    final response = await http.post(
      Uri.parse('$_base/recomendar'),
      headers: _headers(token),
      body: jsonEncode({'evento_id': eventoId}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return AuraFlowResponse.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Error generando ruta');
  }

  Future<String> chat(String token, String eventoId, String pregunta) async {
    final response = await http.post(
      Uri.parse('$_base/chat'),
      headers: _headers(token),
      body: jsonEncode({'evento_id': eventoId, 'pregunta': pregunta}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['respuesta'] ?? '';
    }
    throw Exception('Error en chat');
  }

  Future<List<AuraFlowChatMessage>> historialChat(String token, String eventoId) async {
    final response = await http.get(
      Uri.parse('$_base/chat/$eventoId/historial'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => AuraFlowChatMessage.fromJson(j)).toList();
    }
    return [];
  }
}
