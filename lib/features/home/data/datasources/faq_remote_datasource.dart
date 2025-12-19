import '../../../../core/network/dio_client.dart';

class FaqRemoteDataSource {
  final DioClient dioClient;

  FaqRemoteDataSource(this.dioClient);

  Future<List<dynamic>> getFaqsByCourseId(int courseId) async {
    try {
      final response = await dioClient.get('/faqs/course/$courseId');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('FAQlarni yuklashda xatolik: $e');
    }
  }
}
