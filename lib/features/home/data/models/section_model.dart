import 'dart:convert';

class SectionModel {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int order;
  final List<VideoModel> videos;

  SectionModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.order,
    required this.videos,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'],
      courseId: json['courseId'],
      title: json['title'],
      description: json['description'],
      order: json['order'],
      videos:
          (json['videos'] as List<dynamic>?)
              ?.map((v) => VideoModel.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class VideoModel {
  final int id;
  final int courseId;
  final int? sectionId;
  final String title;
  final String? description;
  final String url;
  final List<String> screenshots;
  final bool isFree;
  final int duration;
  final int order;

  VideoModel({
    required this.id,
    required this.courseId,
    this.sectionId,
    required this.title,
    this.description,
    required this.url,
    required this.screenshots,
    required this.isFree,
    required this.duration,
    required this.order,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    List<String> screenshotsList = [];
    if (json['screenshots'] != null) {
      if (json['screenshots'] is String) {
        try {
          final decoded = jsonDecode(json['screenshots']);
          screenshotsList = (decoded as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        } catch (e) {
          screenshotsList = [];
        }
      } else if (json['screenshots'] is List) {
        screenshotsList = (json['screenshots'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }
    }

    return VideoModel(
      id: json['id'],
      courseId: json['courseId'],
      sectionId: json['sectionId'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      screenshots: screenshotsList,
      isFree: json['isFree'] ?? false,
      duration: json['duration'],
      order: json['order'],
    );
  }

  String get durationText {
    final minutes = duration ~/ 60;
    return '$minutes daqiqa';
  }
}
