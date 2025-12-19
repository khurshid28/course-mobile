import '../../../../core/network/dio_client.dart';

class CommentRemoteDataSource {
  final DioClient dioClient;

  CommentRemoteDataSource(this.dioClient);

  Future<List<dynamic>> getCommentsByCourseId(int courseId) async {
    try {
      final response = await dioClient.get('/comments/course/$courseId');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Izohlarni yuklashda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> createComment({
    required int courseId,
    required String comment,
    required int rating,
    List<String>? screenshots,
  }) async {
    try {
      final response = await dioClient.post(
        '/comments',
        data: {
          'courseId': courseId,
          'comment': comment,
          'rating': rating,
          'screenshots': screenshots ?? [],
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Izoh yozishda xatolik: $e');
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await dioClient.delete('/comments/$commentId');
    } catch (e) {
      throw Exception('Izohni o\'chirishda xatolik: $e');
    }
  }
}
