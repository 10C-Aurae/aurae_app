import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/auth/token_service.dart';
import '../models/ticket.dart';

class TicketService {

  static const String baseUrl = "${Env.baseUrl}/api/v1";

  /// 🔥 CREAR TICKET
  static Future<Ticket> createTicket({
    required String usuarioId,
    required String eventoId,
  }) async {

    final token = await TokenService().getToken();

    if (token == null) {
      throw Exception("Token inválido");
    }

    final url = Uri.parse("$baseUrl/tickets/");

    try {

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "usuario_id": usuarioId,
          "evento_id": eventoId,
          "orden_id": "ORD_${DateTime.now().millisecondsSinceEpoch}",
          "tipo": "general",
          "precio": 0
        }),
      ).timeout(const Duration(seconds: 15));

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 201) {
        return Ticket.fromJson(jsonDecode(response.body));
      }

      throw Exception("Error backend: ${response.body}");

    } catch (e) {
      print("ERROR CREATE TICKET: $e");
      throw Exception("No se pudo generar el ticket");
    }
  }

  /// 🔥 GET TICKETS
  static Future<List<Ticket>> getMyTickets(String userId) async {

    final token = await TokenService().getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/tickets/usuario/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Ticket.fromJson(e)).toList();
    }

    throw Exception("Error cargando tickets");
  }

  /// 🔥 USAR
  static Future<void> useTicket(String ticketId) async {
    final token = await TokenService().getToken();

    await http.post(
      Uri.parse("$baseUrl/tickets/$ticketId/usar"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  /// 🔥 CANCELAR
  static Future<void> cancelTicket(String ticketId) async {
    final token = await TokenService().getToken();

    await http.post(
      Uri.parse("$baseUrl/tickets/$ticketId/cancelar"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  /// 🔥 TICKETS POR EVENTO (ADMIN)
  static Future<List<Ticket>> getTicketsByEvent(String eventId) async {
    final token = await TokenService().getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tickets/evento/$eventId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Ticket.fromJson(e)).toList();
    }
    throw Exception("Error cargando tickets del evento");
  }
}