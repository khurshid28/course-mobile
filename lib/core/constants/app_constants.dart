import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
  static const String apiVersion = '/api/v1';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Phone
  static const String phonePrefix = '+998';

  // Timeouts
  static Duration get connectionTimeout => Duration(
    milliseconds: int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '30000'),
  );
  static Duration get receiveTimeout => Duration(
    milliseconds: int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000'),
  );

  // Pagination
  static const int pageSize = 20;
}
