import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../models/ticket.dart';

class TicketService {

  static const String baseUrl = Env.baseUrl;

  /// 🔹 Obtener tickets por usuario
  static Future<List<Ticket>> getMyTickets(String userId) async {

    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/tickets/usuario/$userId"),
    );

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data.map((e) => Ticket.fromJson(e)).toList();

    } else {
      throw Exception("Error loading tickets");
    }
  }

  /// 🔹 Usar ticket
  static Future<void> useTicket(String ticketId) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/tickets/$ticketId/usar"),
    );

    if (response.statusCode != 200) {
      throw Exception("Error using ticket");
    }
  }

  /// 🔹 Cancelar ticket
  static Future<void> cancelTicket(String ticketId) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/tickets/$ticketId/cancelar"),
    );

    if (response.statusCode != 200) {
      throw Exception("Error canceling ticket");
    }
  }
}