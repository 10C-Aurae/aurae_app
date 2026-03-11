import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/storage/token_storage.dart';
import '../models/user_profile.dart';

class ProfileService {

  static const baseUrl = "https://backend-aurae.onrender.com";

  static Future<UserProfile> getProfile() async {

    final token = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/usuarios/me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("PROFILE STATUS: ${response.statusCode}");
    print("PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return UserProfile.fromJson(data);

    } else {

      throw Exception("Error loading profile");

    }

  }

}