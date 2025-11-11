import 'package:flutter/material.dart';
import 'package:habit_tracker/models/user_model.dart';
import 'package:habit_tracker/services/firestore_service.dart';

class LeaderboardViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _leaderboard = [];
  List<UserModel> get leaderboard => _leaderboard;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor để tự động tải dữ liệu khi ViewModel được tạo
  LeaderboardViewModel() {
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Thông báo cho UI rằng đang loading

    try {
      _leaderboard = await _firestoreService.getLeaderboard(limit: 100);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Thông báo cho UI cập nhật lại với dữ liệu mới hoặc lỗi
    }
  }
}