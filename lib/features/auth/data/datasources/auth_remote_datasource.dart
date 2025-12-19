import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> sendCode(String phone) async {
    try {
      final response = await _dioClient.post(
        '/auth/send-code',
        data: {'phone': phone},
      );
      AppLogger.success('Code sent to $phone');
      return response.data;
    } catch (e) {
      AppLogger.error('Failed to send code: $e');
      rethrow;
    }
  }

  Future<AuthResponse> verifyCode(String phone, String code) async {
    try {
      final response = await _dioClient.post(
        '/auth/verify-code',
        data: {'phone': phone, 'code': code},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token
      if (authResponse.token != null && authResponse.token!.isNotEmpty) {
        _dioClient.setToken(authResponse.token!);
        AppLogger.success('Token saved');
      }

      return authResponse;
    } catch (e) {
      AppLogger.error('Failed to verify code: $e');
      rethrow;
    }
  }

  Future<UserModel> completeProfile({
    required String firstName,
    required String surname,
    String? email,
    required String gender,
    required String region,
    String? avatar,
  }) async {
    try {
      final response = await _dioClient.patch(
        '/auth/complete-profile',
        data: {
          'firstName': firstName,
          'surname': surname,
          'email': email,
          'gender': gender,
          'region': region,
          if (avatar != null) 'avatar': avatar,
        },
      );

      // Backend returns {token, user} object
      final authResponse = AuthResponse.fromJson(response.data);

      // Update token if present
      if (authResponse.token.isNotEmpty) {
        _dioClient.setToken(authResponse.token);
        AppLogger.success('Token updated after profile completion');
      }

      AppLogger.success('Profile completed for ${authResponse.user.firstName}');
      return authResponse.user;
    } catch (e) {
      AppLogger.error('Failed to complete profile: $e');
      rethrow;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dioClient.get('/auth/profile');
      return UserModel.fromJson(response.data);
    } catch (e) {
      AppLogger.error('Failed to get profile: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _dioClient.removeToken();
    AppLogger.info('User logged out');
  }

  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dioClient.post('/upload/image', data: formData);

      AppLogger.success('Image uploaded: ${response.data['url']}');
      return response.data['url'];
    } catch (e) {
      AppLogger.error('Failed to upload image: $e');
      rethrow;
    }
  }
}
