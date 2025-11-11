import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/habit_model.dart';
import '../models/checkin_model.dart';

class FirestoreService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============

  // Check if user exists
  Future<bool> userExists(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists;
  }

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toFirestore());
  }

  // Get user profile
  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toFirestore());
  }

  // ============ HABIT OPERATIONS ============

  // Create habit
  Future<void> createHabit(HabitModel habit) async {
    await _db.collection('habits').doc(habit.id).set(habit.toFirestore());
  }

  // Get user habits (real-time stream)
  Stream<List<HabitModel>> getUserHabitsStream(String userId) {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HabitModel.fromFirestore(doc)).toList();
    });
  }

  // Get user habits (one-time)
  Future<List<HabitModel>> getUserHabits(String userId) async {
    final snapshot = await _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => HabitModel.fromFirestore(doc)).toList();
  }

  // Get single habit
  Future<HabitModel> getHabit(String habitId) async {
    final doc = await _db.collection('habits').doc(habitId).get();
    if (!doc.exists) {
      throw Exception('Habit not found');
    }
    return HabitModel.fromFirestore(doc);
  }

  // Update habit
  Future<void> updateHabit(HabitModel habit) async {
    await _db.collection('habits').doc(habit.id).update(habit.toFirestore());
  }

  // Delete habit and all related check-ins
  Future<void> deleteHabit(String habitId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid; // Lấy UID hiện tại
    if (userId == null) {
      throw Exception('Người dùng chưa được xác thực');
    }

    try {
      await _db.runTransaction((transaction) async {
        // Lấy tài liệu habit
        final habitDoc = _db.collection('habits').doc(habitId);
        final habitSnapshot = await transaction.get(habitDoc);
        if (!habitSnapshot.exists) {
          throw Exception('Thói quen không tồn tại');
        }
        if (habitSnapshot.data()?['userId'] != userId) {
          throw Exception('Bạn không có quyền xóa thói quen này');
        }

        // Xóa tất cả check-ins liên quan thuộc về userId
        final checkinSnapshot = await _db
            .collection('checkins')
            .where('habitId', isEqualTo: habitId)
            .where('userId', isEqualTo: userId) // Lọc theo userId
            .get();
        for (var doc in checkinSnapshot.docs) {
          transaction.delete(doc.reference);
        }

        // Xóa tài liệu habit
        transaction.delete(habitDoc);
      });
    } catch (e) {
      print('Lỗi khi xóa thói quen: $e');
      throw e;
    }
  }

  // ============ CHECKIN OPERATIONS ============

  // Check if habit checked in today
  Future<bool> isHabitCheckedInToday(String habitId) async {
    final today = DateTime.now(); // Múi giờ +07
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Kiểm tra check-in trong ngày hôm nay
      final checkinSnapshot = await _db
          .collection('checkins')
          .where('habitId', isEqualTo: habitId)
          .where(
          'checkinDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('checkinDate', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return checkinSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Lỗi khi kiểm tra check-in: $e');
      return false;
    }
  }

  // Check in habit
  Future<void> checkInHabit(String userId, String habitId) async {
    // Check if already checked in today
    if (await isHabitCheckedInToday(habitId)) {
      throw Exception('Already checked in today');
    }

    // Create check-in record
    final checkin = CheckinModel(
      id: _db
          .collection('checkins')
          .doc()
          .id,
      userId: userId,
      habitId: habitId,
      checkinDate: DateTime.now(),
      pointsEarned: 10,
      coinsEarned: 10,
      streakCount: await _calculateStreak(habitId),
    );
    print('Creating check-in: ${checkin.toFirestore()}');
    await _db.collection('checkins').doc(checkin.id).set(checkin.toFirestore());

    // Update user stats
    print('Updating user stats for userId: $userId');
    await _updateUserStats(userId, checkin.pointsEarned, checkin.coinsEarned);
  }

  // Calculate streak for habit
  Future<int> _calculateStreak(String habitId) async {
    final snapshot = await _db
        .collection('checkins')
        .where('habitId', isEqualTo: habitId)
        .orderBy('checkinDate', descending: true)
        .limit(30)
        .get();

    if (snapshot.docs.isEmpty) return 1;

    int streak = 1;
    DateTime lastDate = DateTime.now();

    for (var doc in snapshot.docs) {
      final checkin = CheckinModel.fromFirestore(doc);
      final daysDiff = lastDate
          .difference(checkin.dateOnly)
          .inDays;

      if (daysDiff == 1) {
        streak++;
        lastDate = checkin.dateOnly;
      } else if (daysDiff > 1) {
        break;
      }
    }

    return streak;
  }

  // Update user stats after check-in
  Future<void> _updateUserStats(String userId, int points, int coins) async {
    final userDoc = _db.collection('users').doc(userId);
    final user = await getUserProfile(userId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckin = user.lastCheckinDate;

    int newStreak = user.currentStreak;

    if (lastCheckin != null) {
      final lastCheckinDate = DateTime(
        lastCheckin.year,
        lastCheckin.month,
        lastCheckin.day,
      );
      final daysDiff = today
          .difference(lastCheckinDate)
          .inDays;

      if (daysDiff == 1) {
        newStreak++;
      } else if (daysDiff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newPoints = user.totalPoints + points;
    final newLevel = _calculateTreeLevel(newPoints);
    final newCoins = user.totalCoins + coins;


    await userDoc.update({
      'totalPoints': newPoints,
      'totalCoins': newCoins,
      'currentStreak': newStreak,
      'longestStreak': newStreak > user.longestStreak ? newStreak : user
          .longestStreak,
      'treeLevel': newLevel,
      'lastCheckinDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Calculate tree level based on points
  int _calculateTreeLevel(int points) {
    if (points < 100) return 0;
    if (points < 300) return 1;
    if (points < 600) return 2;
    if (points < 1000) return 3;
    return 4;
  }

  // Get habit check-ins history
  Future<List<CheckinModel>> getHabitCheckins(String habitId,
      {int limit = 30}) async {
    final snapshot = await _db
        .collection('checkins')
        .where('habitId', isEqualTo: habitId)
        .orderBy('checkinDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc)).toList();
  }

  Future<List<CheckinModel>> getUserCheckins(String userId,
      {int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // 1. Lấy danh sách habit đang active
    final habitSnapshot = await _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final activeHabitIds = habitSnapshot.docs.map((doc) => doc.id).toList();
    if (activeHabitIds.isEmpty) return [];

    // 2. Lấy check-ins thuộc habit đang active trong khoảng thời gian
    final checkinSnapshot = await _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('habitId', whereIn: activeHabitIds)
        .where(
        'checkinDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('checkinDate', descending: true)
        .get();

    // 3. Chuyển thành model
    return checkinSnapshot.docs.map((doc) => CheckinModel.fromFirestore(doc))
        .toList();
  }

  // Get total habits count
  Future<int> getUserHabitsCount(String userId) async {
    final snapshot = await _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }

  // Get total habits count
  Future<int> getUserHabitsCountIsDeleted(String userId) async {
    final snapshot = await _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Get total check-ins count
  Future<int> getUserCheckinsCount(String userId) async {
    // 1. Lấy danh sách habit đang active
    final habitSnapshot = await _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final activeHabitIds = habitSnapshot.docs.map((doc) => doc.id).toList();

    if (activeHabitIds.isEmpty) return 0;

    // 2. Lấy số check-ins chỉ của habit đang active
    final checkinSnapshot = await _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('habitId', whereIn: activeHabitIds)
        .get();

    return checkinSnapshot.docs.length;
  }


  // Lấy danh sách người dùng cho bảng xếp hạng
  Future<List<UserModel>> getLeaderboard({int limit = 100}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('totalPoints', descending: true) // Sắp xếp theo điểm chuỗi
          .orderBy('treeLevel', descending: true) // Sắp xếp phụ theo cấp độ
          .orderBy('updatedAt', descending: true) // Phụ thêm nếu cần
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Lỗi khi lấy bảng xếp hạng: $e');
      throw Exception('Không thể lấy dữ liệu bảng xếp hạng');
    }
  }

  Future<List<CheckinModel>> getCheckins(String userId,
      DateTime startDate,
      DateTime endDate,) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .where(
          'checkinDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('checkinDate', isLessThan: Timestamp.fromDate(endDate))
          .get();
      return snapshot.docs.map((doc) => CheckinModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching check-ins: $e');
    }
  }

}