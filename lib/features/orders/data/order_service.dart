import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../profile/models/order.dart';

class OrderService {
  /// =========================
  /// 🔹 GET ORDERS BY USER ID
  /// =========================
  static Future<List<Order>> getOrdersByUserId(String userId, String token) async {
    final response = await ApiClient.get("/ordenes/usuario/$userId", token);

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception("Error loading orders");
    }
  }
}
