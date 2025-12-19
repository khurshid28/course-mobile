import '../../../../core/network/dio_client.dart';

class TestRemoteDataSource {
  final DioClient dioClient;

  TestRemoteDataSource(this.dioClient);

  Future<List<dynamic>> getTestsByCourseId(int courseId) async {
    try {
      final response = await dioClient.get('/tests/course/$courseId');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Testlarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getTestById(int id) async {
    try {
      final response = await dioClient.get('/tests/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Testni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> submitTest({
    required int testId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await dioClient.post(
        '/tests/submit',
        data: {'testId': testId, 'answers': answers},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Testni yuborishda xatolik: $e');
    }
  }

  Future<List<dynamic>> getUserCertificates() async {
    try {
      final response = await dioClient.get('/tests/certificates/my');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Sertifikatlarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> getCertificate(String certificateNo) async {
    try {
      final response = await dioClient.get(
        '/tests/certificates/$certificateNo',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Sertifikatni yuklashda xatolik: $e');
    }
  }

  Future<String> downloadCertificate(String certificateNo) async {
    try {
      final response = await dioClient.get(
        '/tests/certificates/$certificateNo/download',
      );
      // Return download URL or trigger download
      return '/tests/certificates/$certificateNo/download';
    } catch (e) {
      throw Exception('Sertifikatni yuklashda xatolik: $e');
    }
  }
}
