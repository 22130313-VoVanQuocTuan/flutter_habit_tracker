import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/reading_article_model.dart';
import '../services/reading_challenge_service.dart';
import '../services/auth_service.dart';

class ReadingChallengeViewModel extends ChangeNotifier {
  final ReadingChallengeService _service = ReadingChallengeService();
  final  AuthService authService = AuthService();

  ReadingArticleModel? _currentArticle;
  int _remainingSeconds = 0;
  int _readingTimeSeconds = 0;
  Timer? _timer;
  bool _isReading = false;
  bool _isCompleted = false;
  int _earnedCoins = 0;
  String? _errorMessage;

  // Getters
  ReadingArticleModel? get currentArticle => _currentArticle;
  int get remainingSeconds => _remainingSeconds;
  int get readingTimeSeconds => _readingTimeSeconds;
  bool get isReading => _isReading;
  bool get isCompleted => _isCompleted;
  int get earnedCoins => _earnedCoins;
  String? get errorMessage => _errorMessage;

  bool get hasArticle => _currentArticle != null;
  bool get timeCompleted => _remainingSeconds <= 0;
  bool get canOpenReward => timeCompleted && readingTimeSeconds >= (_currentArticle?.minReadingTime ?? 0);

  // Load specific article
  void loadArticle(ReadingArticleModel article) {
    _currentArticle = article;
    _remainingSeconds = article.minReadingTime;
    _isCompleted = false;
    _readingTimeSeconds = 0;
    _earnedCoins = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // Load today's article (legacy support)
  Future<void> loadTodayArticle(String communityHabitId) async {
    try {
      _errorMessage = null;
      _currentArticle = await _service.getTodayReadingArticle(communityHabitId);

      if (_currentArticle != null) {
        _remainingSeconds = _currentArticle!.minReadingTime;

        // Check if already completed today
        _isCompleted = await _service.hasCompletedTodayReading(
          authService.currentUser?.uid ?? '',
          _currentArticle!.id,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải bài đọc: $e';
      notifyListeners();
    }
  }

  // Start reading
  void startReading() async {
    if (_isReading || _isCompleted) return;

    // Kiểm tra xem bài viết đã được đọc hôm nay chưa
    final userId = authService.currentUser?.uid;
    if (userId != null && _currentArticle != null) {
      bool hasCompletedToday = await _service.hasCompletedTodayReading(
        userId,
        _currentArticle!.id,
      );
      if (hasCompletedToday) {
        _errorMessage = 'Bạn đã đọc bài này hôm nay. Hãy quay lại vào ngày mai!';
        notifyListeners();
        return;
      }
    }

    _isReading = true;
    _readingTimeSeconds = 0;
    notifyListeners();

    // Timer đếm ngược thời gian yêu cầu
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _readingTimeSeconds++;

      if (_remainingSeconds > 0) {
        _remainingSeconds--;
      }

      notifyListeners();

      // Nếu hoàn thành thời gian, dừng timer
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  // Stop reading
  void stopReading() {
    _timer?.cancel();
    _isReading = false;
    notifyListeners();
  }

  // Exit reading (thoát mà chưa hoàn thành)
  void exitReading() {
    _timer?.cancel();
    _isReading = false;
    _readingTimeSeconds = 0;
    _remainingSeconds = _currentArticle?.minReadingTime ?? 0;
    notifyListeners();
  }

  // Open reward (mở hộp quà)
  Future<void> openReward() async {
    if (!canOpenReward) return;

    final userId = authService.currentUser?.uid;
    if (userId == null || _currentArticle == null) return;

    try {
      // Tính random coins
      _earnedCoins = _service.calculateRandomCoins(
        _currentArticle!.minCoin,
        _currentArticle!.maxCoin,
        _readingTimeSeconds,
        _currentArticle!.minReadingTime,
      );

      // Lưu tiến độ
      await _service.saveReadingProgress(
        userId: userId,
        articleId: _currentArticle!.id,
        readingTimeSeconds: _readingTimeSeconds,
        earnedCoins: _earnedCoins,
      );

      _isCompleted = true;
      _isReading = false;
      _timer?.cancel();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi mở quà: $e';
      notifyListeners();
    }
  }

  // Reset reading (quay lại state ban đầu)
  void reset() {
    _timer?.cancel();
    _isReading = false;
    _isCompleted = false;
    _readingTimeSeconds = 0;
    _earnedCoins = 0;
    if (_currentArticle != null) {
      _remainingSeconds = _currentArticle!.minReadingTime;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}