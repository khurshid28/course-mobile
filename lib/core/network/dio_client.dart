import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  DioClient(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add token if available
          final token = _prefs.getString(AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Log only POST, PUT, PATCH, DELETE requests
          if (options.method != 'GET') {
            print('🌐 ${options.method} => ${options.uri}');
            if (options.data != null) {
              print('📤 Data: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log only POST, PUT, PATCH, DELETE responses
          if (response.requestOptions.method != 'GET') {
            print('✅ ${response.statusCode} ${response.requestOptions.uri}');
            print('📦 Response: ${response.data}');
          }

          return handler.next(response);
        },
        onError: (error, handler) {
          // Translate backend errors to Uzbek
          if (error.response?.data != null && error.response?.data is Map) {
            final errorData = error.response!.data as Map<String, dynamic>;
            if (errorData['message'] != null) {
              final translatedMessage = _translateErrorToUzbek(
                errorData['message'].toString(),
              );
              errorData['message'] = translatedMessage;
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Add logger interceptor (only in debug mode)
    // LogInterceptor disabled - using custom interceptor instead that only logs POST/PUT/PATCH/DELETE
    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     LogInterceptor(
    //       requestBody: true,
    //       responseBody: true,
    //       requestHeader: true,
    //       responseHeader: false,
    //       error: true,
    //       logPrint: (obj) => debugPrint(obj.toString()),
    //     ),
    //   );
    // }
  }

  Dio get dio => _dio;

  // Translate backend errors to Uzbek
  String _translateErrorToUzbek(String errorMessage) {
    final translations = <String, String>{
      // Auth errors
      'User not found': 'Foydalanuvchi topilmadi',
      'Invalid or expired code': 'Noto\'g\'ri yoki eskirgan kod',
      'Unauthorized': 'Ruxsat berilmagan',

      // Course errors
      'Course not found': 'Kurs topilmadi',
      'Already enrolled in this course': 'Siz allaqachon kursga yozilgansiz',
      'You must be enrolled to leave feedback':
          'Fikr qoldirish uchun kursga yozilishingiz kerak',

      // Test errors
      'Test topilmadi': 'Test topilmadi',
      'Siz bu kursga yozilmagansiz': 'Siz bu kursga yozilmagansiz',
      'Test allaqachon tugallangan': 'Test allaqachon tugallangan',
      'Vaqt tugadi': 'Vaqt tugadi',
      'Savol topilmadi': 'Savol topilmadi',
      'Session topilmadi': 'Session topilmadi',
      'Certificate not found': 'Sertifikat topilmadi',
      'Certificate PDF not found': 'Sertifikat PDF topilmadi',

      // Payment errors
      'This course is free': 'Bu kurs bepul',
      'Insufficient balance': 'Hisobingizda mablag\'lar yetarli emas',
      'Payment not found': 'To\'lov topilmadi',
      'Promo code topilmadi': 'Promo kod topilmadi',
      'Promo code faol emas': 'Promo kod faol emas',
      'Promo code muddati tugagan': 'Promo kod muddati tugagan',
      'Siz bu promo code\'dan foydalangansiz':
          'Siz bu promo koddan foydalangansiz',
      'Siz maksimal promo code limitiga yetdingiz (3 ta)':
          'Siz maksimal promo kod limitiga yetdingiz (3 ta)',
      'Promo code foydalanish limiti tugagan':
          'Promo kod foydalanish limiti tugagan',
      'Kurs topilmadi': 'Kurs topilmadi',
      'Promo code noto\'g\'ri sozlangan': 'Promo kod noto\'g\'ri sozlangan',
      'Promo code faqat kurs sotib olishda ishlatiladi':
          'Promo kod faqat kurs sotib olishda ishlatiladi',

      // Teacher errors
      'Teacher not found': 'O\'qituvchi topilmadi',
      'Rating must be between 1 and 5': 'Baho 1 dan 5 gacha bo\'lishi kerak',
      'Faqat o\'qituvchilar kurs yaratishi mumkin':
          'Faqat o\'qituvchilar kurs yaratishi mumkin',

      // Section errors
      'Section with ID': 'Bo\'lim topilmadi',

      // File errors
      'Only image files are allowed!': 'Faqat rasm fayllarga ruxsat berilgan!',
      'Only video files are allowed!': 'Faqat video fayllarga ruxsat berilgan!',
      'File too large': 'Fayl juda katta',

      // Comment errors
      'Faqat rasm fayllarga ruxsat berilgan!':
          'Faqat rasm fayllarga ruxsat berilgan!',
    };

    // Check for exact match
    if (translations.containsKey(errorMessage)) {
      return translations[errorMessage]!;
    }

    // Check for partial match
    for (var entry in translations.entries) {
      if (errorMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no translation found, return original message
    return errorMessage;
  }

  // Set token
  void setToken(String token) {
    _prefs.setString(AppConstants.tokenKey, token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Remove token
  void removeToken() {
    _prefs.remove(AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  // Clear all storage
  Future<void> clearAllStorage() async {
    await _prefs.clear();
    _dio.options.headers.remove('Authorization');
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
