import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/auth/token_service.dart';
import '../../../core/config/env.dart';


class AuthService {

  // static const String baseUrl = "https://backend-aurae.onrender.com";
  static const String baseUrl = Env.baseUrl;
  

  static final TokenService _tokenService = TokenService();

  // LOGIN
  static Future<String> login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/auth/login"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: "username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}",
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);
      final token = data["access_token"];

      await _tokenService.saveToken(token);

      return token;

    } else {

      throw Exception("Invalid credentials");

    }

  }

  // REGISTER
  static Future<void> register(
    String name,
    String email,
    String password,
    List<String> interests,
  ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/usuarios/"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "nombre": name,
        "email": email,
        "password": password,
        "vector_intereses": interests,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error creating account");
    }

  }

  // GET TOKEN
  static Future<String?> getToken() async {
    return await _tokenService.getToken();
  }

  // LOGOUT
  static Future<void> logout() async {
    await _tokenService.deleteToken();
  }

}