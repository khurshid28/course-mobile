import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '📱 CourseApp';

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText 🔍 $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText ℹ️ $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText ⚠️ $message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText ❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText ✅ $message');
    }
  }

  static void network(String message, {String? tag}) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix $tagText 🌐 $message');
    }
  }
}
