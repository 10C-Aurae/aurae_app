import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../models/cola_virtual.dart';

class ColaService {
  static const String _base = '${Env.baseUrl}/api/v1/colas';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ColaVirtual>> misTurnos(String token) async {
    final response = await http.get(
      Uri.parse('$_base/mis-turnos'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => ColaVirtual.fromJson(j)).toList();
    }
    throw Exception('Error cargando turnos');
  }

  Future<ColaVirtual> unirse(
    String token,
    String standId,
    String eventoId, {
    String? servicioId,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/unirse'),
      headers: _headers(token),
      body: jsonEncode({
        'stand_id': standId,
        'evento_id': eventoId,
        if (servicioId != null) 'servicio_id': servicioId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ColaVirtual.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Error al unirse a la cola');
  }

  Future<ColaVirtual> confirmarLlegada(String token, String colaId) async {
    final response = await http.post(
      Uri.parse('$_base/$colaId/confirmar-llegada'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return ColaVirtual.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error confirmando llegada');
  }

  Future<void> cancelarTurno(String token, String colaId) async {
    final response = await http.post(
      Uri.parse('$_base/$colaId/cancelar'),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error cancelando turno');
    }
  }
}
