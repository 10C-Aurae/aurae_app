import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../models/ticket.dart';

class TicketService {

  final String baseUrl = "${Env.baseUrl}/api/v1/tickets";

  /// 🔥 GET tickets del usuario
  Future<List<Ticket>> getUserTickets(String token, String userId) async {

    final response = await http.get(
      Uri.parse("$baseUrl/usuario/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data.map((e) => Ticket.fromJson(e)).toList();

    } else {
      throw Exception("Error loading tickets");
    }
  }

  /// 🔥 USAR ticket
  Future<void> useTicket(String token, String ticketId) async {

    final response = await http.post(
      Uri.parse("$baseUrl/$ticketId/usar"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error using ticket");
    }
  }

  /// 🔥 CANCELAR ticket
  Future<void> cancelTicket(String token, String ticketId) async {

    final response = await http.post(
      Uri.parse("$baseUrl/$ticketId/cancelar"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Error canceling ticket");
    }
  }
}