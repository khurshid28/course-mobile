import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class TeacherRemoteDataSource {
  final Dio _dio;

  TeacherRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/teachers');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('O\'qituvchilarni yuklashda xatolik');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Tizimga kirish talab qilinadi');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Serverga ulanishda xatolik',
      );
    } catch (e) {
      throw Exception('Kutilmagan xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getTeacherById(int id) async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/teachers/$id');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('O\'qituvchi ma\'lumotini yuklashda xatolik');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Tizimga kirish talab qilinadi');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Serverga ulanishda xatolik',
      );
    } catch (e) {
      throw Exception('Kutilmagan xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> rateTeacher(int teacherId, int rating) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/teachers/$teacherId/rate',
        data: {'rating': rating},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Baholashda xatolik');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Tizimga kirish talab qilinadi');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('Noto\'g\'ri baho qiymati');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Serverga ulanishda xatolik',
      );
    } catch (e) {
      throw Exception('Kutilmagan xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getUserRating(int teacherId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/teachers/$teacherId/user-rating',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Foydalanuvchi baholashini yuklashda xatolik');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Tizimga kirish talab qilinadi');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Serverga ulanishda xatolik',
      );
    } catch (e) {
      throw Exception('Kutilmagan xatolik: $e');
    }
  }
}
