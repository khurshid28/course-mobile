import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCoursesLocalDataSource {
  final SharedPreferences _prefs;
  static const String _savedCoursesKey = 'saved_courses';

  SavedCoursesLocalDataSource(this._prefs);

  Future<List<Map<String, dynamic>>> getSavedCourses() async {
    final jsonString = _prefs.getString(_savedCoursesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCourse(Map<String, dynamic> course) async {
    final courses = await getSavedCourses();
    
    // Check if already saved
    final index = courses.indexWhere((c) => c['id'] == course['id']);
    if (index == -1) {
      courses.add(course);
      await _saveToPrefs(courses);
    }
  }

  Future<void> removeCourse(int courseId) async {
    final courses = await getSavedCourses();
    courses.removeWhere((c) => c['id'] == courseId);
    await _saveToPrefs(courses);
  }

  Future<bool> isSaved(int courseId) async {
    final courses = await getSavedCourses();
    return courses.any((c) => c['id'] == courseId);
  }

  Future<void> syncWithRemote(List<Map<String, dynamic>> remoteCourses) async {
    await _saveToPrefs(remoteCourses);
  }

  Future<void> _saveToPrefs(List<Map<String, dynamic>> courses) async {
    final jsonString = json.encode(courses);
    await _prefs.setString(_savedCoursesKey, jsonString);
  }

  Future<void> clear() async {
    await _prefs.remove(_savedCoursesKey);
  }
}
