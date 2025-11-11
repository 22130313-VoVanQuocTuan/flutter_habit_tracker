import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingArticleModel {
  final String id;
  final String communityHabitId;
  final String title;
  final String content;
  final int minReadingTime;
  final int minCoin;
  final int maxCoin;
  final DateTime createdAt;

  ReadingArticleModel({
    required this.id,
    required this.communityHabitId,
    required this.title,
    required this.content,
    required this.minReadingTime,
    required this.minCoin,
    required this.maxCoin,
    required this.createdAt,
  });

  factory ReadingArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingArticleModel(
      id: doc.id,
      communityHabitId: data['communityHabitId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      minReadingTime: data['minReadingTime'] ?? 300,
      minCoin: data['minCoin'] ?? 50,
      maxCoin: data['maxCoin'] ?? 200,
      createdAt: (data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityHabitId': communityHabitId,
      'title': title,
      'content': content,
      'minReadingTime': minReadingTime,
      'minCoin': minCoin,
      'maxCoin': maxCoin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}