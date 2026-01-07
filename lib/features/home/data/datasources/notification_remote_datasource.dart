import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class NotificationRemoteDataSource {
  final DioClient _dioClient = getIt<DioClient>();

  Future<List<dynamic>> getUserNotifications() async {
    try {
      final response = await _dioClient.get('/notifications');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      final errorMessage = e.response?.data != null && e.response!.data is Map
          ? (e.response!.data['message'] ??
                'Bildirishnomalarni yuklashda xatolik')
          : 'Bildirishnomalarni yuklashda xatolik';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bildirishnomalarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await _dioClient.get('/notifications/unread-count');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMessage = e.response?.data != null && e.response!.data is Map
          ? (e.response!.data['message'] ??
                'O\'qilmagan xabarlar sonini yuklashda xatolik')
          : 'O\'qilmagan xabarlar sonini yuklashda xatolik';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('O\'qilmagan xabarlar sonini yuklashda xatolik: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dioClient.patch('/notifications/$id/read');
    } on DioException catch (e) {
      final errorMessage = e.response?.data != null && e.response!.data is Map
          ? (e.response!.data['message'] ??
                'Bildirishnomani o\'qilgan qilishda xatolik')
          : 'Bildirishnomani o\'qilgan qilishda xatolik';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Bildirishnomani o\'qilgan qilishda xatolik: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.patch('/notifications/mark-all-read');
    } on DioException catch (e) {
      final errorMessage = e.response?.data != null && e.response!.data is Map
          ? (e.response!.data['message'] ??
                'Barcha bildirishnomalarni o\'qilgan qilishda xatolik')
          : 'Barcha bildirishnomalarni o\'qilgan qilishda xatolik';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(
        'Barcha bildirishnomalarni o\'qilgan qilishda xatolik: $e',
      );
    }
  }
}
