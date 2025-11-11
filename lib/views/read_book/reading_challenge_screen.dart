import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/reading_article_model.dart';
import 'package:habit_tracker/viewmodels/reading_challenge_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingChallengeScreen extends StatefulWidget {
  final String communityHabitId;
  final String communityHabitTitle;

  const ReadingChallengeScreen({
    super.key,
    required this.communityHabitId,
    required this.communityHabitTitle,
  });

  @override
  State<ReadingChallengeScreen> createState() => _ReadingChallengeScreenState();
}



class _ReadingChallengeScreenState extends State<ReadingChallengeScreen> {
  late ReadingChallengeViewModel _viewModel;
  List<ReadingArticleModel> _articles = [];
  bool _isLoadingArticles = false;
  String? _selectedArticleId;
  Map<String, DateTime?> _lastReadDates = {}; // Track last read date for each article

  @override
  void initState() {
    super.initState();
    _viewModel = ReadingChallengeViewModel();
    _loadAllArticles();
  }



  Future<void> _loadAllArticles() async {
    setState(() => _isLoadingArticles = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('readingArticles')
          .where('communityHabitId', isEqualTo: widget.communityHabitId)
          .orderBy('createdAt', descending: true)
          .get();

      final articles = querySnapshot.docs
          .map((doc) => ReadingArticleModel.fromFirestore(doc))
          .toList();

      // Load last read dates for each article
      final userId = FirebaseAuth.instance.currentUser?.uid;
      Map<String, DateTime?> lastReadDates = {};

      if (userId != null) {
        for (var article in articles) {
          final doc = await FirebaseFirestore.instance
              .collection('readingProgress')
              .where('userId', isEqualTo: userId)
              .where('articleId', isEqualTo: article.id)
              .orderBy('completedAt', descending: true)
              .limit(1)
              .get();

          if (doc.docs.isNotEmpty) {
            lastReadDates[article.id] =
                (doc.docs.first['completedAt'] as Timestamp).toDate();
          }
        }
      }

      setState(() {
        _articles = articles;
        _lastReadDates = lastReadDates;
        if (articles.isNotEmpty) {
          _selectedArticleId = articles.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bài đọc: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingArticles = false);
    }
  }

  void _selectArticle(String articleId) {
    final lastRead = _lastReadDates[articleId];

    // Check if user already read today
    if (lastRead != null) {
      final now = DateTime.now();
      final isToday = lastRead.year == now.year &&
          lastRead.month == now.month &&
          lastRead.day == now.day;

      if (isToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã đọc bài này hôm nay. Hãy quay lại vào ngày mai! 📅'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _selectedArticleId = articleId);
    _viewModel.loadArticle(_articles.firstWhere((a) => a.id == articleId));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thử Thách Đọc Sách'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<ReadingChallengeViewModel>(
          builder: (context, viewModel, _) {
            // Loading articles
            if (_isLoadingArticles) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // No articles
            if (_articles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có bài đọc nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay Lại'),
                    ),
                  ],
                ),
              );
            }

            // Completed state
            if (viewModel.isCompleted) {
              return _buildCompletedState(context, viewModel);
            }

            // Reading state
            if (viewModel.isReading) {
              final article = _articles.firstWhere(
                    (a) => a.id == _selectedArticleId,
                orElse: () => _articles.first,
              );
              return _buildReadingState(context, viewModel, article);
            }

            // Articles list state
            return _buildArticlesListState(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildArticlesListState(
      BuildContext context,
      ReadingChallengeViewModel viewModel,
      ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.communityHabitTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn Bài Đọc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Có ${_articles.length} bài đọc để bạn chọn',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Articles list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(_articles.length, (index) {
                final article = _articles[index];
                final isSelected = _selectedArticleId == article.id;
                final minutes = article.minReadingTime ~/ 60;
                final seconds = article.minReadingTime % 60;

                return GestureDetector(
                  onTap: () => _selectArticle(article.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF667eea)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? const Color(0xFF667eea).withOpacity(0.05)
                          : Colors.white,
                    ),
                    child: Column(
                      children: [
                        // Article title and index
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF667eea).withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF667eea),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF667eea)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            article.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Already read badge
                                        if (_lastReadDates[article.id] != null)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '✓ Đã đọc',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${article.id.substring(0, 8)}...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF667eea),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),

                        // Article preview and requirements
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Content preview
                              Text(
                                article.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              // Requirements row
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined,
                                          size: 16, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.monetization_on,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${article.minCoin}-${article.maxCoin}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Ngày ${(index + 1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 32),

          // Start reading button
          // Start reading button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedArticleId != null
                    ? () {
                  final selected = _articles.firstWhere(
                        (a) => a.id == _selectedArticleId,
                  );
                  // Check if the selected article was read today
                  final lastRead = _lastReadDates[selected.id];
                  final now = DateTime.now();
                  final isReadToday = lastRead != null &&
                      lastRead.year == now.year &&
                      lastRead.month == now.month &&
                      lastRead.day == now.day;

                  if (!isReadToday) {
                    _viewModel.loadArticle(selected);
                    _viewModel.startReading();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bạn đã đọc bài này hôm nay. Hãy quay lại vào ngày mai! 📅',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
                    : null,
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Bắt Đầu Đọc',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedArticleId != null
                      ? (_lastReadDates[_selectedArticleId] != null &&
                      _lastReadDates[_selectedArticleId]!.year == DateTime.now().year &&
                      _lastReadDates[_selectedArticleId]!.month == DateTime.now().month &&
                      _lastReadDates[_selectedArticleId]!.day == DateTime.now().day
                      ? Colors.grey // Disabled color
                      : const Color(0xFF667eea)) // Enabled color
                      : Colors.grey, // Disabled color when no article selected
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReadingState(
      BuildContext context,
      ReadingChallengeViewModel viewModel,
      ReadingArticleModel article,
      ) {
    return Column(
      children: [
        // Reading content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  article.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timer section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thời Gian Còn Lại',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Timer display
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: viewModel.timeCompleted
                        ? [Colors.amber[400]!, Colors.amber[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: viewModel.timeCompleted
                          ? Colors.amber.withOpacity(0.4)
                          : Colors.blue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: viewModel.timeCompleted
                      ? const Icon(
                    Icons.card_giftcard,
                    size: 60,
                    color: Colors.white,
                  )
                      : Text(
                    '${viewModel.remainingSeconds}s',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              if (viewModel.timeCompleted && viewModel.canOpenReward)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => viewModel.openReward(),
                    icon: const Icon(Icons.card_giftcard, size: 24),
                    label: const Text(
                      'Mở Hộp Quà',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      viewModel.exitReading();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thoát',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(
      BuildContext context,
      ReadingChallengeViewModel viewModel,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gift box animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[300]!, Colors.amber[600]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Congratulations text
          const Text(
            'Chúc Mừng!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Bạn đã hoàn thành bài đọc',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 32),

          // Earned coins display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[100]!, Colors.orange[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Bạn nhận được',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${viewModel.earnedCoins}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  viewModel.reset();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Quay Lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}