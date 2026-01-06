class TestModel {
  final int id;
  final String title;
  final String? description;
  final int duration;
  final int maxDuration;
  final int passingScore;
  final int minCorrectAnswers;
  final String availabilityType;
  final int availableAfterDays;
  final bool isActive;
  final List<TestQuestionModel> questions;
  final TestResultModel? lastAttempt;
  final bool isAvailable;

  TestModel({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    required this.maxDuration,
    required this.passingScore,
    required this.minCorrectAnswers,
    required this.availabilityType,
    required this.availableAfterDays,
    required this.isActive,
    required this.questions,
    this.lastAttempt,
    required this.isAvailable,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    // Agar backend isAvailable bermasa, birinchi testni (availableAfterDays = 0) ochiq deb hisoblaymiz
    final bool isAvailable =
        json['isAvailable'] ??
        (json['availableAfterDays'] == 0 &&
            json['availabilityType'] == 'ANYTIME');

    return TestModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      maxDuration: json['maxDuration'] ?? 60,
      passingScore: json['passingScore'],
      minCorrectAnswers: json['minCorrectAnswers'] ?? 18,
      availabilityType: json['availabilityType'],
      availableAfterDays: json['availableAfterDays'],
      isActive: json['isActive'],
      questions:
          (json['questions'] as List?)
              ?.map((q) => TestQuestionModel.fromJson(q))
              .toList() ??
          [],
      lastAttempt: json['lastAttempt'] != null
          ? TestResultModel.fromJson(json['lastAttempt'])
          : null,
      isAvailable: isAvailable,
    );
  }
}

class TestQuestionModel {
  final int id;
  final String question;
  final List<String> options;
  final int order;

  TestQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.order,
  });

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(
        json['options'] is String
            ? (json['options'] as String).split(',')
            : json['options'],
      ),
      order: json['order'],
    );
  }
}

class TestResultModel {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final bool isPassed;
  final DateTime completedAt;

  TestResultModel({
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.isPassed,
    required this.completedAt,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      score: json['score'],
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      isPassed: json['isPassed'],
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}

class TestSessionModel {
  final int sessionId;
  final TestModel test;
  final DateTime startedAt;
  final DateTime expiresAt;
  final Map<int, int> currentAnswers;

  TestSessionModel({
    required this.sessionId,
    required this.test,
    required this.startedAt,
    required this.expiresAt,
    required this.currentAnswers,
  });

  factory TestSessionModel.fromJson(Map<String, dynamic> json) {
    return TestSessionModel(
      sessionId: json['sessionId'],
      test: TestModel.fromJson(json['test']),
      startedAt: DateTime.parse(json['startedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      currentAnswers: Map<int, int>.from(json['currentAnswers'] ?? {}),
    );
  }
}
