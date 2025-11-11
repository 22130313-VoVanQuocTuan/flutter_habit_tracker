import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/checkin_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _userProfile;
  List<CheckinModel> _recentCheckins = [];
  int _totalActiveHabits = 0; // CHỈ ĐẾM HABITS ĐANG HOẠT ĐỘNG
  int _totalCheckins = 0;
  int _todayCheckins = 0; // SỐ CHECK-IN HÔM NAY
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get userProfile => _userProfile;
  List<CheckinModel> get recentCheckins => _recentCheckins;
  int get totalHabits => _totalActiveHabits;
  int get totalCheckins => _totalCheckins;
  int get todayCheckins => _todayCheckins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Tree image path
  String get treeImagePath {
    final level = _userProfile?.treeLevel ?? 0;
    return 'assets/images/trees/tree_level_$level.png';
  }

  // Tree level description
  String get treeLevelDescription {
    switch (_userProfile?.treeLevel ?? 0) {
      case 0:
        return 'Hạt giống 🌱';
      case 1:
        return 'Mầm non 🌿';
      case 2:
        return 'Cây non 🌳';
      case 3:
        return 'Cây trưởng thành 🌴';
      case 4:
        return 'Cây ra hoa 🌸';
      default:
        return 'Tiếp tục chăm sóc cây của bạn nhé! 🌾';
    }
  }


  // Progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (_userProfile == null) return 0.0;

    final currentPoints = _userProfile!.totalPoints;
    const levelThresholds = [0, 100, 300, 600, 1000];
    final currentLevel = _userProfile!.treeLevel;

    if (currentLevel >= levelThresholds.length - 1) return 1.0;

    final currentLevelPoints = levelThresholds[currentLevel];
    final nextLevelPoints = levelThresholds[currentLevel + 1];
    final pointsInLevel = currentPoints - currentLevelPoints;
    final pointsNeeded = nextLevelPoints - currentLevelPoints;

    return (pointsInLevel / pointsNeeded).clamp(0.0, 1.0);
  }

  // Points to next level
  int get pointsToNextLevel {
    if (_userProfile == null) return 0;

    const levelThresholds = [0, 100, 300, 600, 1000];
    final currentLevel = _userProfile!.treeLevel;

    if (currentLevel >= levelThresholds.length - 1) return 0;

    return levelThresholds[currentLevel + 1] - _userProfile!.totalPoints;
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

  // Load profile data
  Future<void> loadProfile() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('User not authenticated');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Load user profile
      _userProfile = await _firestoreService.getUserProfile(userId);

      // Load recent check-ins (last 30 days)
      _recentCheckins = await _firestoreService.getUserCheckins(
        userId,
        days: 30,
      );

      // Load statistics - CHỈ ĐẾM HABITS ĐANG HOẠT ĐỘNG (isActive = true)
      _totalActiveHabits = await _firestoreService.getUserHabitsCount(userId);

      _totalCheckins = await _firestoreService.getUserCheckinsCount(userId);

      // Calculate today's check-ins
      _todayCheckins = _getTodayCheckinsCount();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // Get check-ins for a specific date
  List<CheckinModel> getCheckinsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _recentCheckins.where((checkin) {
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

  // Get today's check-ins count
  int _getTodayCheckinsCount() {
    final today = DateTime.now();
    return getCheckinsForDate(today).length;
  }

  // Get weekly activity (last 7 days)
  Map<DateTime, int> getWeeklyActivity() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    final Map<DateTime, int> activity = {};

    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        weekAgo.year,
        weekAgo.month,
        weekAgo.day + i,
      );
      activity[date] = getCheckinsForDate(date).length;
    }

    return activity;
  }

  // Get monthly activity
  Map<DateTime, int> getMonthlyActivity() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 29));

    final Map<DateTime, int> activity = {};

    for (int i = 0; i < 30; i++) {
      final date = DateTime(
        monthAgo.year,
        monthAgo.month,
        monthAgo.day + i,
      );
      activity[date] = getCheckinsForDate(date).length;
    }

    return activity;
  }

  // FIXED: Calculate completion rate - CHỈ TÍNH HABITS ĐANG HOẠT ĐỘNG
  double get completionRate {
    if (_totalActiveHabits == 0) return 0.0;

    // Tính số ngày kể từ khi tạo account
    final daysActive = _userProfile?.createdAt != null
        ? DateTime.now().difference(_userProfile!.createdAt).inDays + 1
        : 1;

    // Expected check-ins = Số habits ĐANG HOẠT ĐỘNG * Số ngày
    final expectedCheckins = _totalActiveHabits * daysActive;

    if (expectedCheckins == 0) return 0.0;

    // Completion rate = (Tổng check-ins / Expected check-ins) * 100
    return (_totalCheckins / expectedCheckins * 100).clamp(0, 100);
  }

  //NEW: Completion rate HÔM NAY
  double get todayCompletionRate {
    if (_totalActiveHabits == 0) return 0.0;
    return (_todayCheckins / _totalActiveHabits * 100).clamp(0, 100);
  }

  // NEW: Average completion rate (last 7 days)
  double get weeklyCompletionRate {
    if (_totalActiveHabits == 0) return 0.0;

    final weeklyActivity = getWeeklyActivity();
    final totalWeeklyCheckins = weeklyActivity.values.reduce((a, b) => a + b);
    final expectedWeeklyCheckins = _totalActiveHabits * 7;

    if (expectedWeeklyCheckins == 0) return 0.0;

    return (totalWeeklyCheckins / expectedWeeklyCheckins * 100).clamp(0, 100);
  }

  Future<void> updateProfile(UserModel user) async {
    _setLoading(true);
    try {
      await _firestoreService.updateUserProfile(user);
      _userProfile = user;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
    }
  }

  // NEW: Get completion status message
  String get completionStatusMessage {
    if (_totalActiveHabits == 0) return 'Tạo thói quen đầu tiên của bạn!';
    if (todayCompletionRate == 100) return 'Ngày hoàn hảo! 🎉';
    if (todayCompletionRate >= 75) return 'Tiến bộ lớn! 👍';
    if (todayCompletionRate >= 50) return 'Tiếp tục đi! 💪';
    if (todayCompletionRate > 0) return 'Khởi đầu tốt đẹp! 🌱';
    return 'Time to check in! ⏰';
  }
}