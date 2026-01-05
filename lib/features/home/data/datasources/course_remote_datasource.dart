import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';

class CourseRemoteDataSource {
  final DioClient _dioClient;

  CourseRemoteDataSource(this._dioClient);

  Future<List<dynamic>> getAllCourses() async {
    try {
      final response = await _dioClient.get('/courses');
      AppLogger.success('Fetched ${response.data.length} courses');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch courses: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourseById(int id) async {
    try {
      final response = await _dioClient.get('/courses/$id');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch course $id: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSavedCourses() async {
    try {
      final response = await _dioClient.get('/courses/saved/list');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch saved courses: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getEnrolledCourses() async {
    try {
      final response = await _dioClient.get('/courses/enrolled/list');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch enrolled courses: $e');
      rethrow;
    }
  }

  Future<void> toggleSaveCourse(int courseId) async {
    try {
      await _dioClient.post('/courses/$courseId/save');
      AppLogger.success('Toggled save for course $courseId');
    } catch (e) {
      AppLogger.error('Failed to toggle save course: $e');
      rethrow;
    }
  }

  Future<void> addFeedback({
    required int courseId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dioClient.post(
        '/courses/$courseId/feedback',
        data: {'rating': rating, 'comment': comment},
      );
      AppLogger.success('Feedback added for course $courseId');
    } catch (e) {
      AppLogger.error('Failed to add feedback: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCoursesByCategory(int categoryId) async {
    try {
      final response = await _dioClient.get('/courses/category/$categoryId');
      AppLogger.success('Fetched courses for category $categoryId');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch courses by category: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getAllTeachers() async {
    try {
      final response = await _dioClient.get('/teachers');
      AppLogger.success('Fetched ${response.data.length} teachers');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch teachers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rateCourse(int courseId, int rating) async {
    try {
      final response = await _dioClient.post(
        '/courses/$courseId/rate',
        data: {'rating': rating},
      );
      AppLogger.success('Rated course $courseId with $rating stars');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to rate course: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserCourseRating(int courseId) async {
    try {
      final response = await _dioClient.get('/courses/$courseId/user-rating');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to get user course rating: $e');
      rethrow;
    }
  }

  Future<void> deleteRating(int courseId) async {
    try {
      await _dioClient.delete('/courses/$courseId/rate');
      AppLogger.success('Deleted rating for course $courseId');
    } catch (e) {
      AppLogger.error('Failed to delete rating: $e');
      rethrow;
    }
  }
}
