import 'package:dio/dio.dart';
import 'dart:io' as io;
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
    List<String>? images,
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
      if (images != null && images.isNotEmpty) {
        print('Adding ${images.length} images');
        for (String imagePath in images) {
          final file = io.File(imagePath);
          final fileName = imagePath.split('/').last;
          final bytes = await file.readAsBytes();

          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: fileName,
          );
          formData.files.add(MapEntry('images', multipartFile));
          print('Added image: $imagePath');
        }
      }

      print('FormData fields: ${formData.fields}');
      print('FormData files: ${formData.files.length} files');

      final response = await dioClient.post('/comments/legacy', data: formData);
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
