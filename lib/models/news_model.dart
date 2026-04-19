import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final bool isBreaking;
  final DateTime createdAt;
  final String createdBy;
  final String locationScope; // 'Global' or 'India'
  final String? state;
  final String? district;
  final List<String> likes; // List of user UIDs who liked this post
  final String? subtitle;
  final String? sourceName;
  final String? sourceUrl;
  final int? readingTime;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.isBreaking,
    required this.createdAt,
    required this.createdBy,
    this.locationScope = 'Global',
    this.state,
    this.district,
    this.likes = const [],
    this.subtitle,
    this.sourceName,
    this.sourceUrl,
    this.readingTime,
  });

  factory NewsModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NewsModel(
      id: documentId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      isBreaking: map['isBreaking'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      locationScope: map['locationScope'] ?? 'Global',
      state: map['state'],
      district: map['district'],
      likes: List<String>.from(map['likes'] ?? []),
      subtitle: map['subtitle'],
      sourceName: map['sourceName'],
      sourceUrl: map['sourceUrl'],
      readingTime: map['readingTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'isBreaking': isBreaking,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'locationScope': locationScope,
      'likes': likes,
      if (state != null) 'state': state,
      if (district != null) 'district': district,
      if (subtitle != null) 'subtitle': subtitle,
      if (sourceName != null) 'sourceName': sourceName,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (readingTime != null) 'readingTime': readingTime,
    };
  }
}
