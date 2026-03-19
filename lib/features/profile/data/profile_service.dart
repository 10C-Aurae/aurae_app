import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/config/env.dart';
import '../models/user_profile.dart';

class ProfileService {

  /// =========================
  /// 🔹 GET MY PROFILE
  /// =========================
  Future<UserProfile> getMyProfile(String token) async {

    final response = await ApiClient.get(
      "/usuarios/me",
      token,
    );

    print("PROFILE STATUS: ${response.statusCode}");
    print("PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return UserProfile.fromJson(data);

    } else if (response.statusCode == 401) {

      throw Exception("Unauthorized - Token inválido");

    } else {

      throw Exception("Error loading profile");
    }
  }

  /// =========================
  /// 🔹 UPDATE PROFILE
  /// =========================
  Future<UserProfile> updateProfile(
    String token,
    String nombre,
    String avatarUrl,
    List<String> intereses,
  ) async {

    final response = await ApiClient.patch(
      "/usuarios/me",
      token,
      {
        "nombre": nombre,
        "avatar_url": avatarUrl,
        "vector_intereses": intereses,
      },
    );

    print("UPDATE PROFILE STATUS: ${response.statusCode}");
    print("UPDATE PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return UserProfile.fromJson(data);

    } else {

      throw Exception("Error updating profile");
    }
  }

}