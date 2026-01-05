import 'dart:async';
import '../models/test_model.dart';
import '../../../home/data/datasources/test_remote_datasource.dart';

class TestRepository {
  final TestRemoteDataSource dataSource;

  TestRepository({required this.dataSource});

  // Kurs testlarini olish
  Future<List<TestModel>> getCourseTests(int courseId) async {
    try {
      final data = await dataSource.getTestsByCourseId(courseId);
      return data
          .map((t) => TestModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Testlarni yuklashda xatolik: $e');
    }
  }

  // Test'ni boshlash
  Future<TestSessionModel> startTest(int testId) async {
    try {
      final data = await dataSource.startTest(testId);
      return TestSessionModel.fromJson(data);
    } catch (e) {
      throw Exception('Testni boshlashda xatolik: $e');
    }
  }

  // Javob yuborish (real-time)
  Future<void> submitAnswer({
    required int sessionId,
    required int questionId,
    required int selectedAnswer,
  }) async {
    try {
      await dataSource.submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        selectedAnswer: selectedAnswer,
      );
    } catch (e) {
      throw Exception('Javobni yuborishda xatolik: $e');
    }
  }

  // Session holati
  Future<Map<String, dynamic>> getSessionStatus(int sessionId) async {
    try {
      return await dataSource.getSessionStatus(sessionId);
    } catch (e) {
      throw Exception('Session holatini olishda xatolik: $e');
    }
  }

  // Test'ni tugatish
  Future<Map<String, dynamic>> completeTest(int sessionId) async {
    try {
      return await dataSource.completeTest(sessionId);
    } catch (e) {
      throw Exception('Testni tugatishda xatolik: $e');
    }
  }

  // Certificate verify
  Future<Map<String, dynamic>> verifyCertificate(String certificateNo) async {
    try {
      return await dataSource.verifyCertificate(certificateNo);
    } catch (e) {
      throw Exception('Sertifikatni tasdiqlashda xatolik: $e');
    }
  }
}
