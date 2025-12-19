import '../../../../core/network/dio_client.dart';

class SectionRemoteDataSource {
  final DioClient dioClient;

  SectionRemoteDataSource(this.dioClient);

  Future<List<dynamic>> getSectionsByCourseId(int courseId) async {
    try {
      final response = await dioClient.get('/sections/course/$courseId');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Seksiyalarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getSectionById(int id) async {
    try {
      final response = await dioClient.get('/sections/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Seksiyani yuklashda xatolik: $e');
    }
  }
}
