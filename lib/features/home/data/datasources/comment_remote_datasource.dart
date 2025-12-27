import 'package:dio/dio.dart';
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
    List<String>? imagePaths,
  }) async {
    try {
      print(
        'Creating comment - courseId: $courseId, comment: $comment, rating: $rating',
      );

      FormData formData = FormData.fromMap({
        'courseId': courseId,
        'comment': comment,
        'rating': rating,
      });

      // Add images if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        print('Adding ${imagePaths.length} images to screenshots field');
        for (String imagePath in imagePaths) {
          final multipartFile = await MultipartFile.fromFile(imagePath);
          formData.files.add(MapEntry('screenshots', multipartFile));
          print('Added image: $imagePath');
        }
      }

      print('FormData fields: ${formData.fields}');
      print('FormData files: ${formData.files.length} files');

      final response = await dioClient.post('/comments', data: formData);
      print('Comment created successfully: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error creating comment: $e');
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
