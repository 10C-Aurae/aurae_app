import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {

  static const String baseUrl =
      "https://backend-aurae.onrender.com/api/v1";

  static Map<String, String> headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> get(
      String endpoint, String token) {

    return http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers(token),
    );
  }

  static Future<http.Response> patch(
      String endpoint,
      String token,
      Map<String, dynamic> body) {

    return http.patch(
      Uri.parse("$baseUrl$endpoint"),
      headers: headers(token),
      body: jsonEncode(body),
    );
  }
}