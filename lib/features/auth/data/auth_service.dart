import 'package:dio/dio.dart';

class AuthService {

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://backend-aurae.onrender.com",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<String> login(String email, String password) async {

    final response = await dio.post(
      "/api/v1/auth/login",
      data: {
        "username": email,
        "password": password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return response.data["access_token"];
  }

  static Future<void> register(
      String nombre,
      String email,
      String password
      ) async {

    await dio.post(
      "/api/v1/usuarios",
      data: {
        "nombre": nombre,
        "email": email,
        "password": password,
        "vector_intereses": []
      },
    );

  }

}