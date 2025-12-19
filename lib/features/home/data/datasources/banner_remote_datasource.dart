import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';

class BannerRemoteDataSource {
  final DioClient _dioClient = getIt<DioClient>();

  Future<List<dynamic>> getActiveBanners() async {
    try {
      final response = await _dioClient.get('/banners');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Bannerlarni yuklashda xatolik: $e');
    }
  }
}
