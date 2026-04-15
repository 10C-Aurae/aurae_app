import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../models/event.dart';

class EventService {

  final String baseUrl = "${Env.baseUrl}/api/v1/eventos";

  Future<List<Event>> getEvents() async {

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data.map((e) => Event.fromJson(e)).toList();

    } else {
      throw Exception("Error loading events");
    }
  }

  Future<Event> getEventById(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return Event.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error loading event details for: $id");
    }
  }
}