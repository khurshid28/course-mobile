import '../constants/app_constants.dart';

class ImageUtils {
  /// Converts relative image URL to absolute URL
  static String getFullImageUrl(String? imageUrl) {
    print('🔧 ImageUtils.getFullImageUrl called with: $imageUrl');

    if (imageUrl == null || imageUrl.isEmpty) {
      print('⚠️ ImageUrl is null or empty, returning empty string');
      return '';
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('✅ Already absolute URL: $imageUrl');
      return imageUrl;
    }

    final fullUrl = '${AppConstants.baseUrl}$imageUrl';
    print('🔗 Created full URL: $fullUrl');
    print('📍 Base URL used: ${AppConstants.baseUrl}');
    return fullUrl;
  }

  /// Check if image URL is valid
  static bool hasValidImageUrl(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty;
  }
}
