import '../constants/app_constants.dart';

extension StringImageExtension on String {
  /// Builds full image URL if needed
  String get asImageUrl {
    if (isEmpty) return this;

    // Agar allaqachon to'liq URL bo'lsa
    if (startsWith('http://') || startsWith('https://')) {
      return this;
    }

    // Agar / bilan boshlansa, baseUrl bilan birlashtirish
    if (startsWith('/')) {
      return '${AppConstants.baseUrl}$this';
    }

    // Boshqa hollarda ham baseUrl qo'shish
    return '${AppConstants.baseUrl}/$this';
  }
}

extension NullableStringImageExtension on String? {
  /// Builds full image URL for nullable strings
  String get asImageUrl {
    if (this == null || this!.isEmpty) return '';
    return this!.asImageUrl;
  }
}
