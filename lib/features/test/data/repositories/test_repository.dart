import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/test_model.dart';

class TestRepository {
  final String baseUrl;
  final String token;

  TestRepository({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Kurs testlarini olish
  Future<List<TestModel>> getCourseTests(int courseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tests/course/$courseId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((t) => TestModel.fromJson(t)).toList();
    } else {
      throw Exception('Failed to load tests');
    }
  }

  // Test'ni boshlash
  Future<TestSessionModel> startTest(int testId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tests/$testId/start'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TestSessionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to start test');
    }
  }

  // Javob yuborish (real-time)
  Future<void> submitAnswer({
    required int sessionId,
    required int questionId,
    required int selectedAnswer,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tests/session/$sessionId/answer'),
      headers: _headers,
      body: json.encode({
        'questionId': questionId,
        'selectedAnswer': selectedAnswer,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit answer');
    }
  }

  // Session holati
  Future<Map<String, dynamic>> getSessionStatus(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tests/session/$sessionId/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get session status');
    }
  }

  // Test'ni tugatish
  Future<Map<String, dynamic>> completeTest(int sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tests/session/$sessionId/complete'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to complete test');
    }
  }

  // Certificate verify
  Future<Map<String, dynamic>> verifyCertificate(String certificateNo) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tests/certificates/verify/$certificateNo'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Certificate not found');
    }
  }
}
