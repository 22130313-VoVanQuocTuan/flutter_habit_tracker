import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_tracker/models/lottery_comment_model.dar.dart';
import 'package:habit_tracker/models/lottery_result_model.dart';


class LotteryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if the portal is open (Sunday afternoon, e.g., after 12 PM)
  bool isPortalOpen() {
    final now = DateTime.now();
    return now.weekday == DateTime.sunday && now.hour >= 12;
  }

  // Kiểm tra xem người dùng đã bình luận trong tuần hiện tại chưa
  Future<bool> hasUserCommented(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final snapshot = await _firestore
        .collection('future_portal_comments')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();
    return snapshot.docs.isNotEmpty;
  }
  // Kiểm tra số dư coin của người dùng
  Future<int> checkUserCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }
      final data = userDoc.data() as Map<String, dynamic>;
      return (data['totalCoins'] as num?)?.toInt() ?? 0;
    } catch (e) {
      print('Lỗi kiểm tra số dư coin: $e');
      throw Exception('Lỗi kiểm tra số dư coin: $e');
    }
  }

  // Kiểm tra xem đã có kết quả xổ số trong tuần hiện tại chưa
  Future<bool> hasLotteryResultForCurrentWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final snapshot = await _firestore
        .collection('lottery_results')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Thêm bình luận mới vào Firestore
  Future<void> addComment({
    required String username,
    required int betAmount,
    required int number,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    if (!isPortalOpen()) {
      throw Exception('Cổng chỉ mở vào chiều Chủ Nhật');
    }

    if (await hasUserCommented(userId)) {
      throw Exception('Người dùng đã bình luận trong tuần này');
    }
    // Kiểm tra số dư coin
    final userCoins = await checkUserCoins(userId);
    if (betAmount > userCoins) {
      throw Exception('Số coin không đủ để đặt cược');
    }

    // TODO: Check if user has enough coins (integrate with your coin system)

    final comment = LotteryCommentModel(
      id: '', // Firestore will generate ID
      userId: userId,
      username: username,
      betAmount: betAmount,
      number: number,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('future_portal_comments')
        .add(comment.toFirestore());
  }

  // Tải bình luận của tuần hiện tại từ Firestore
  Future<List<LotteryCommentModel>> loadComments() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final snapshot = await _firestore
          .collection('future_portal_comments')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .orderBy('timestamp', descending: true)
          .get();
      print('Dữ liệu Firestore: ${snapshot.docs.map((doc) => doc.data()).toList()}');
      final comments = snapshot.docs
          .map((doc) => LotteryCommentModel.fromFirestore(doc))
          .toList();
      print('Bình luận đã ánh xạ: $comments');
      return comments;
    } catch (e) {
      print('Lỗi tải bình luận: $e');
      rethrow;
    }
  }

  // Tải kết quả xổ số mới nhất của tuần hiện tại từ Firestore
  Future<LotteryResultModel?> loadLatestResult() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final snapshot = await _firestore
        .collection('lottery_results')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return LotteryResultModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

    /// Lưu kết quả xổ số và cộng coin cho người thắng
  Future<void> saveLotteryResult({
    required int winningNumber,
    required List<String> winners,
    required double rewardMultiplier,
  }) async {
    try {
      // Kiểm tra xem đã có kết quả trong tuần này chưa
      if (await hasLotteryResultForCurrentWeek()) {
        throw Exception('Kỳ xổ số tuần này đã được quay!');
      }
      final result = LotteryResultModel(
        id: '',
        winningNumber: winningNumber,
        winners: winners,
        rewardMultiplier: rewardMultiplier,
        timestamp: DateTime.now(),
      );
      await _firestore.collection('lottery_results').add(result.toFirestore());

      // Cộng coin cho người thắng
      final winnerComments = await getWinners(winningNumber);
      for (var winner in winnerComments.where((c) => winners.contains(c.username))) {
        final reward = (winner.betAmount * rewardMultiplier).toInt();
        await _firestore.collection('users').doc(winner.userId).update({
          'totalCoins': FieldValue.increment(reward),
        });
      }
    } catch (e) {
      print('Lỗi khi lưu kết quả xổ số: $e');
      rethrow;
    }
  }

  // Lấy danh sách người thắng
  Future<List<LotteryCommentModel>> getWinners(int winningNumber) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final snapshot = await _firestore
        .collection('future_portal_comments')
        .where('number', isEqualTo: winningNumber)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();
    return snapshot.docs
        .map((doc) => LotteryCommentModel.fromFirestore(doc))
        .toList();
  }

  // Xóa bình luận của tuần trước (dành cho admin)
  Future<void> clearPreviousWeekComments() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final snapshot = await _firestore
          .collection('future_portal_comments')
          .where('timestamp', isLessThan: Timestamp.fromDate(startOfWeek))
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('Đã xóa ${snapshot.docs.length} bình luận cũ');
    } catch (e) {
      print('Lỗi khi xóa bình luận cũ: $e');
      rethrow;
    }
  }
}