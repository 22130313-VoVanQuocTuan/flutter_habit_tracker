import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/user_model.dart';
import 'package:habit_tracker/services/tree_health_service.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class HabitViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final TreeHealthService _treeHealthService = TreeHealthService();

  List<HabitModel> _habits = [];
  Map<String, bool> _checkedInToday = {};
  int _totalCheckinsCount = 0; // Thêm thuộc tính để theo dõi tổng số check-in
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<HabitModel> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get activeHabitsCount => _habits.where((h) => h.isActive).length;
  int get checkedInTodayCount => _checkedInToday.values.where((v) => v).length;
  int get totalCheckinsCount => _totalCheckinsCount; // Getter cho tổng số check-in

  // Check if habit is checked in today
  bool isCheckedInToday(String habitId) {
    return _checkedInToday[habitId] ?? false;
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load habits and counts
  Future<void> loadHabits() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('Người dùng chưa được xác thực');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Tải danh sách thói quen
      _habits = await _firestoreService.getUserHabits(userId);

      // Tải trạng thái check-in hôm nay
      for (var habit in _habits) {
        _checkedInToday[habit.id] =
        await _firestoreService.isHabitCheckedInToday(habit.id);
      }

      // Tải tổng số check-in
      _totalCheckinsCount = await _firestoreService.getUserCheckinsCount(userId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Listen to habits stream
  void listenToHabits() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _firestoreService.getUserHabitsStream(userId).listen(
          (habits) {
        _habits = habits;
        // Cập nhật số lượng thói quen
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );

    // Lắng nghe thay đổi check-in (có thể cần stream riêng cho check-in)
    _firestoreService.getUserCheckins(userId).then((checkins) {
      _totalCheckinsCount = checkins.length;
      notifyListeners();
    });
  }

  // Add new habit
  Future<bool> addHabit({
    required String title,
    String? description,
    required String frequency,
    required DateTime reminderTime,
    bool reminderEnabled = true,
    String color = '#4CAF50',
    String icon = '🌱',
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('Người dùng chưa được xác thực');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Lấy danh sách thói quen hiện tại
      final habits = await _firestoreService.getUserHabits(userId);

      // Giới hạn số lượng thói quen
      if (habits.length >= 10) {
        _setError('Bạn đã đạt giới hạn 10 thói quen!');
        _setLoading(false);
        return false;
      }

      // Kiểm tra trùng lặp title
      if (habits.any((habit) => habit.title.toLowerCase() == title.toLowerCase())) {
        _setError('Thói quen "$title" đã tồn tại!');
        _setLoading(false);
        return false;
      }

      // Kiểm tra thời gian tạo thói quen gần nhất
      final lastHabit = habits.isNotEmpty
          ? habits.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;
      if (lastHabit != null &&
          DateTime.now().difference(lastHabit.createdAt).inSeconds < 60) {
        _setError('Vui lòng đợi 60 giây trước khi tạo thói quen mới!');
        _setLoading(false);
        return false;
      }

      final habit = HabitModel(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        description: description,
        frequency: frequency,
        reminderTime: reminderTime,
        reminderEnabled: reminderEnabled,
        color: color,
        icon: icon,
        createdAt: DateTime.now(), // Thêm trường createdAt vào HabitModel
      );

      await _firestoreService.createHabit(habit);

      // Schedule notification if enabled
      if (reminderEnabled) {
        await _notificationService.scheduleHabitReminder(
          habit.id,
          habit.title,
          habit.reminderTime,
        );
        print('⏰ reminderTime: ${habit.reminderTime}');
        print('🕓 now: ${DateTime.now()}');
      }

      // Cập nhật danh sách thói quen và số lượng
      await loadHabits();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update habit
  Future<bool> updateHabit(HabitModel habit) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestoreService.updateHabit(habit);

      // Update notification
      if (habit.reminderEnabled) {
        await _notificationService.scheduleHabitReminder(
          habit.id,
          habit.title,
          habit.reminderTime,
        );
      } else {
        await _notificationService.cancelHabitReminder(habit.id);
      }

      await loadHabits();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete habit
  Future<bool> deleteHabit(String habitId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firestoreService.deleteHabit(habitId);
      await _notificationService.cancelHabitReminder(habitId);

      // Cập nhật danh sách thói quen và số lượng check-in
      await loadHabits();
      _checkedInToday.remove(habitId); // Xóa trạng thái check-in hôm nay
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Check-in habit
// Thay thế method checkInHabit trong HabitViewModel

  Future<bool> checkInHabit(String habitId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    try {
      // Lấy profile người dùng
      final user = await _firestoreService.getUserProfile(userId);
      if (user == null) {
        _setError('User profile not found');
        _setLoading(false);
        return false;
      }

      // Kiểm tra xem đã check-in thói quen này hôm nay chưa
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final checkins = await _firestoreService.getHabitCheckins(habitId);
      if (checkins.any((checkin) =>
      checkin.checkinDate.isAfter(startOfDay) &&
          checkin.checkinDate.isBefore(endOfDay))) {
        _setError('Đã check-in thói quen này hôm nay');
        _setLoading(false);
        return false;
      }

      // Kiểm tra số lượng check-in hôm nay
      final allCheckinsToday = await _firestoreService.getCheckins(
        userId,
        startOfDay,
        endOfDay,
      );
      if (allCheckinsToday.length >= 3) {
        _setError('Bạn đã đạt giới hạn 3 check-in mỗi ngày!');
        _setLoading(false);
        return false;
      }

      // Thêm check-in
      await _firestoreService.checkInHabit(userId, habitId);

      // ✅ CẬP NHẬT NGAY TRẠNG THÁI CHECK-IN TRONG MAP
      _checkedInToday[habitId] = true;

      // Cập nhật profile người dùng
      final newPoints = user.totalPoints + 10;

      // Chỉ tăng streak và treeHealth một lần mỗi ngày
      UserModel updatedUser;
      final lastCheckinDate = user.lastCheckinDate;
      final isNewDay = lastCheckinDate == null ||
          !DateTime(lastCheckinDate.year, lastCheckinDate.month, lastCheckinDate.day)
              .isAtSameMomentAs(DateTime(today.year, today.month, today.day));

      if (isNewDay) {
        final newStreak = user.currentStreak + 1;
        final newLongestStreak =
        newStreak > user.longestStreak ? newStreak : user.longestStreak;
        updatedUser = user.copyWith(
          totalPoints: newPoints,
          currentStreak: newStreak,
          longestStreak: newLongestStreak,
          lastCheckinDate: today,
        );
        // Cập nhật sức khỏe cây và bệnh
        updatedUser = await _treeHealthService.onDailyCheckIn(updatedUser);
      } else {
        updatedUser = user.copyWith(
          totalPoints: newPoints,
          lastCheckinDate: today,
        );
      }

      await _firestoreService.updateUserProfile(updatedUser);

      // ✅ THÔNG BÁO CẬP NHẬT UI
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to check in: $e');
      _setLoading(false);
      return false;
    }
  }




  // Get habit by ID
  HabitModel? getHabitById(String habitId) {
    try {
      return _habits.firstWhere((habit) => habit.id == habitId);
    } catch (e) {
      return null;
    }
  }

}