import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';

class CategoryRemoteDataSource {
  final DioClient _dioClient;

  CategoryRemoteDataSource(this._dioClient);

  Future<List<dynamic>> getAllCategories() async {
    try {
      final response = await _dioClient.get('/categories');
      AppLogger.success('Fetched ${response.data.length} categories');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch categories: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategoryById(int id) async {
    try {
      final response = await _dioClient.get('/categories/$id');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to fetch category $id: $e');
      rethrow;
    }
  }
}
