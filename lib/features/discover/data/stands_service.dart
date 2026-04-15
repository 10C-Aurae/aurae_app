import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/config/env.dart';

class StandsService {
  final String baseUrl = "${Env.baseUrl}/api/v1/stands";

  Future<List<dynamic>> getStandsByEvent(String token, String eventId) async {
    final response = await ApiClient.get("/stands/admin/evento/$eventId", token);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error loading stands for event: $eventId");
    }
  }

  Future<List<dynamic>> publicGetStandsByEvent(String eventId) async {
    final response = await http.get(Uri.parse("$baseUrl/evento/$eventId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error loading stands for event: $eventId");
    }
  }

  Future<void> createStand(String token, Map<String, dynamic> data) async {
    final response = await ApiClient.post("/stands/", token, data);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body)['detail'] ?? "Error creating stand";
      throw Exception(error);
    }
  }

  Future<void> updateStand(String token, String id, Map<String, dynamic> data) async {
    final response = await ApiClient.patch("/stands/$id", token, data);
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'] ?? "Error updating stand";
      throw Exception(error);
    }
  }

  Future<void> deleteStand(String token, String id) async {
    final response = await ApiClient.delete("/stands/$id", token);
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body)['detail'] ?? "Error deleting stand";
      throw Exception(error);
    }
  }
}
