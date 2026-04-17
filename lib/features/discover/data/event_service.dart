import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/config/env.dart';
import '../models/event.dart';

class EventService {
  final String baseUrl = "${Env.baseUrl}/api/v1/eventos";

  Future<List<Event>> getEvents() async {
    final response = await http.get(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
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
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return Event.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error loading event details for: $id");
    }
  }

  Future<Event> createEvent(String token, Map<String, dynamic> data) async {
    final response = await ApiClient.post("/eventos/", token, data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Event.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['detail'] ?? "Error creating event";
      throw Exception(error);
    }
  }

  Future<Event> updateEvent(String token, String id, Map<String, dynamic> data) async {
    final response = await ApiClient.patch("/eventos/$id/", token, data);
    if (response.statusCode == 200) {
      return Event.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body)['detail'] ?? "Error updating event";
      throw Exception(error);
    }
  }

  Future<void> deleteEvent(String token, String id) async {
    final response = await ApiClient.delete("/eventos/$id/", token);
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body)['detail'] ?? "Error deleting event";
      throw Exception(error);
    }
  }
}