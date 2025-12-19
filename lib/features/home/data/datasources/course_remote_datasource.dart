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
}
