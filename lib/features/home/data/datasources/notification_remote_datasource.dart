import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class NotificationRemoteDataSource {
  final DioClient _dioClient = getIt<DioClient>();

  Future<List<dynamic>> getUserNotifications() async {
    try {
      final response = await _dioClient.get('/notifications');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Bildirishnomalarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await _dioClient.get('/notifications/unread-count');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('O\'qilmagan xabarlar sonini yuklashda xatolik: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dioClient.patch('/notifications/$id/read');
    } catch (e) {
      throw Exception('Bildirishnomani o\'qilgan qilishda xatolik: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.patch('/notifications/mark-all-read');
    } catch (e) {
      throw Exception(
        'Barcha bildirishnomalarni o\'qilgan qilishda xatolik: $e',
      );
    }
  }
}
