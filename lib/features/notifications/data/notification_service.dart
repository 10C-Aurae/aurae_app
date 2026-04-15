import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getNotifications(String token) async {
    final res = await ApiClient.get('/notificaciones/', token);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    }
    throw Exception('Error cargando notificaciones');
  }

  Future<int> getUnreadCount(String token) async {
    final res = await ApiClient.get('/notificaciones/no-leidas', token);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['no_leidas'] as num).toInt();
    }
    return 0;
  }

  Future<void> markAllRead(String token) async {
    await ApiClient.post('/notificaciones/marcar-leidas', token, {});
  }

  Future<void> markOneRead(String token, String id) async {
    await ApiClient.patch('/notificaciones/$id/leer', token, {});
  }
}
