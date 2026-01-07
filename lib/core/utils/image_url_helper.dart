import '../constants/app_constants.dart';

class ImageUrlHelper {
  /// Build full image URL from relative path or return as-is if already full URL
  static String buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Agar allaqachon to'liq URL bo'lsa, o'zgartirishsiz qaytarish
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Agar / bilan boshlansa, baseUrl bilan birlashtirish
    if (imagePath.startsWith('/')) {
      return '${AppConstants.baseUrl}$imagePath';
    }

    // Boshqa hollarda ham baseUrl qo'shish (/ qo'shib)
    return '${AppConstants.baseUrl}/$imagePath';
  }

  /// Build avatar URL
  static String buildAvatarUrl(String? avatar) {
    return buildImageUrl(avatar);
  }

  /// Build course thumbnail URL
  static String buildThumbnailUrl(String? thumbnail) {
    return buildImageUrl(thumbnail);
  }

  /// Build teacher photo URL
  static String buildTeacherPhotoUrl(String? photoUrl) {
    return buildImageUrl(photoUrl);
  }

  /// Build video thumbnail URL
  static String buildVideoThumbnailUrl(String? thumbnailUrl) {
    return buildImageUrl(thumbnailUrl);
  }
}
