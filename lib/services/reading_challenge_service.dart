import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reading_article_model.dart';

class ReadingChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy bài đọc hôm nay cho người dùng
  Future<ReadingArticleModel?> getTodayReadingArticle(String communityHabitId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('readingArticles')
          .where('communityHabitId', isEqualTo: communityHabitId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ReadingArticleModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Lỗi lấy bài đọc: $e');
      return null;
    }
  }

  // Lưu tiến độ đọc của người dùng
  Future<void> saveReadingProgress({
    required String userId,
    required String articleId,
    required int readingTimeSeconds,
    required int earnedCoins,
  }) async {
    try {
      await _db.collection('readingProgress').add({
        'userId': userId,
        'articleId': articleId,
        'readingTimeSeconds': readingTimeSeconds,
        'earnedCoins': earnedCoins,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật coins người dùng
      await _db.collection('users').doc(userId).update({
        'totalCoins': FieldValue.increment(earnedCoins),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi lưu tiến độ đọc: $e');
      throw e;
    }
  }

  // Kiểm tra xem đã hoàn thành bài đọc hôm nay chưa
  Future<bool> hasCompletedTodayReading(String userId, String articleId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('readingProgress')
          .where('userId', isEqualTo: userId)
          .where('articleId', isEqualTo: articleId)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Random coin dựa trên thời gian đọc
  int calculateRandomCoins(int minCoin, int maxCoin, int readingTimeSeconds, int minReadingTime) {
    // Nếu đọc đủ thời gian, random coin
    if (readingTimeSeconds >= minReadingTime) {
      return minCoin + (DateTime.now().millisecondsSinceEpoch.remainder(maxCoin - minCoin + 1));
    }
    // Nếu đọc không đủ, trả về 0
    return 0;
  }
}