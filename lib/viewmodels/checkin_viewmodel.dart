import 'package:flutter/foundation.dart';
import '../models/checkin_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CheckinViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<CheckinModel> _checkins = [];
  Map<String, List<CheckinModel>> _habitCheckins = {};
  Map<String, bool> _checkedInToday = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CheckinModel> get checkins => _checkins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get checkedInToday => _checkedInToday; // Trả về trạng thái check-in

  // Get checkins for specific habit
  List<CheckinModel> getHabitCheckins(String habitId) {
    return _habitCheckins[habitId] ?? [];
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

  // Load all user check-ins
  Future<void> loadCheckins({int days = 30}) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('Người dùng chưa được xác thực');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _checkins = await _firestoreService.getUserCheckins(userId, days: days);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Load check-ins for specific habit and update checkedInToday
  Future<void> loadHabitCheckins(String habitId, {int limit = 30}) async {
    _setLoading(true);
    _setError(null);

    try {
      final checkins = await _firestoreService.getHabitCheckins(habitId, limit: limit);
      _habitCheckins[habitId] = checkins;

      // Cập nhật trạng thái check-in hôm nay từ Firestore
      final isChecked = await _firestoreService.isHabitCheckedInToday(habitId);
      _checkedInToday[habitId] = isChecked;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Check if habit checked in today
  Future<bool> isHabitCheckedInToday(String habitId) async {
    try {
      return await _firestoreService.isHabitCheckedInToday(habitId);
    } catch (e) {
      return false;
    }
  }

  // Perform check-in
  Future<bool> checkInHabit(String habitId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('Người dùng chưa được xác thực');
      return false;
    }

    try {
      // Check if already checked in
      final alreadyCheckedIn = await isHabitCheckedInToday(habitId);
      if (alreadyCheckedIn) {
        _setError('Đã Check-in hôm nay');
        return false;
      }

      await _firestoreService.checkInHabit(userId, habitId);

      // Reload checkins
      await loadHabitCheckins(habitId);

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Get check-in streak for habit
  int getHabitStreak(String habitId) {
    final habitCheckins = _habitCheckins[habitId];
    if (habitCheckins == null || habitCheckins.isEmpty) return 0;

    int streak = 0;
    DateTime lastDate = DateTime.now();

    for (var checkin in habitCheckins) {
      final daysDiff = lastDate.difference(checkin.dateOnly).inDays;

      if (daysDiff <= 1) {
        streak++;
        lastDate = checkin.dateOnly;
      } else {
        break;
      }
    }

    return streak;
  }

  // Get check-ins for specific date
  List<CheckinModel> getCheckinsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _checkins.where((checkin) {
      final checkinDate = DateTime(
        checkin.checkinDate.year,
        checkin.checkinDate.month,
        checkin.checkinDate.day,
      );
      return checkinDate == targetDate;
    }).toList();
  }

  // Check if date has check-ins
  bool hasCheckinsOn(DateTime date) {
    return getCheckinsForDate(date).isNotEmpty;
  }

  // Get weekly check-in count
  Map<DateTime, int> getWeeklyCheckins() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    final Map<DateTime, int> weeklyData = {};

    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        weekAgo.year,
        weekAgo.month,
        weekAgo.day + i,
      );
      weeklyData[date] = getCheckinsForDate(date).length;
    }

    return weeklyData;
  }

  // Get monthly check-in count
  Map<DateTime, int> getMonthlyCheckins() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 29));

    final Map<DateTime, int> monthlyData = {};

    for (int i = 0; i < 30; i++) {
      final date = DateTime(
        monthAgo.year,
        monthAgo.month,
        monthAgo.day + i,
      );
      monthlyData[date] = getCheckinsForDate(date).length;
    }

    return monthlyData;
  }

  // Get total check-ins count
  int getTotalCheckinsCount() {
    return _checkins.length;
  }

  // Get total points earned
  int getTotalPointsEarned() {
    return _checkins.fold(0, (sum, checkin) => sum + checkin.pointsEarned);
  }

  // Get best streak
  int getBestStreak() {
    if (_checkins.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 1;

    final sortedCheckins = List<CheckinModel>.from(_checkins)
      ..sort((a, b) => b.checkinDate.compareTo(a.checkinDate));

    for (int i = 0; i < sortedCheckins.length - 1; i++) {
      final current = sortedCheckins[i];
      final next = sortedCheckins[i + 1];

      final daysDiff = current.dateOnly.difference(next.dateOnly).inDays;

      if (daysDiff == 1) {
        currentStreak++;
      } else {
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        currentStreak = 1;
      }
    }

    return currentStreak > maxStreak ? currentStreak : maxStreak;
  }

  void clearHabitData(String habitId) {
    _habitCheckins.remove(habitId); // Xóa check-ins của habit
    _checkedInToday.remove(habitId); // Xóa trạng thái check-in hôm nay
    notifyListeners();
  }

}