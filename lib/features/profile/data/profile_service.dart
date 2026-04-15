import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../models/user_profile.dart';
import '../models/ble_token.dart';

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

  /// =========================
  /// 🔹 GET BLE TOKEN
  /// =========================
  Future<BleToken> getBleToken(String token) async {
    final response = await ApiClient.get("/usuarios/me/ble-token", token);
    if (response.statusCode == 200) {
      return BleToken.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error loading BLE token");
    }
  }

  /// =========================
  /// 🔹 ROTATE BLE TOKEN
  /// =========================
  Future<BleToken> rotateBleToken(String token) async {
    final response = await ApiClient.post("/usuarios/me/ble-token/rotar", token, {});
    if (response.statusCode == 200) {
      return BleToken.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error rotating BLE token");
    }
  }

  /// =========================
  /// 🔹 DELETE ACCOUNT
  /// =========================
  Future<void> deleteAccount(String token, String userId) async {
    final response = await ApiClient.delete("/usuarios/$userId", token);
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body)['detail'] ?? "Error eliminando cuenta";
      throw Exception(error);
    }
  }
}