import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

  static const String baseUrl = "https://backend-aurae.onrender.com";

  // LOGIN
  static Future<String> login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/auth/login"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": email,
        "password": password,
      },
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data["access_token"];

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

}