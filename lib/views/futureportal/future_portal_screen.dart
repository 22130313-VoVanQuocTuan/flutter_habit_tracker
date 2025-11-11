import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/lottery_comment_model.dar.dart';
import 'package:habit_tracker/models/lottery_result_model.dart';
import 'package:habit_tracker/services/lottery_service.dart';
import 'package:intl/intl.dart';

class MyFuturePortalScreen extends StatefulWidget {
  const MyFuturePortalScreen({super.key});

  @override
  State<MyFuturePortalScreen> createState() => _MyFuturePortalScreenState();
}

class _MyFuturePortalScreenState extends State<MyFuturePortalScreen> {
  final LotteryService _lotteryService = LotteryService();
  List<LotteryCommentModel> _comments = [];
  LotteryResultModel? _lotteryResult;
  bool _hasCommented = false;
  bool _isLoading = true;
  bool _isPortalOpen = false;

  @override
  void initState() {
    super.initState();
    //_checkPortalStatus();
    _loadData();
  }

  // Check if portal is open
  void _checkPortalStatus() {
    setState(() {
      _isPortalOpen = _lotteryService.isPortalOpen();
    });
  }

  // Load comments and lottery result
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _lotteryService.loadComments();
      final result = await _lotteryService.loadLatestResult();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        _comments = comments;
        _lotteryResult = result;
        _hasCommented = userId != null && comments.any((comment) => comment.userId == userId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show dialog for betting coins and commenting a number
  void _showBetDialog() {
    if (!_isPortalOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cổng chỉ mở vào chiều Chủ Nhật!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasCommented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chỉ được bình luận một lần duy nhất!')),
      );
      return;
    }

    final betController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt Cược và Bình Luận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: betController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số coins cược',
                hintText: 'Nhập số coins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bình luận con số',
                hintText: 'Nhập con số của bạn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final betAmount = int.tryParse(betController.text);
              final number = int.tryParse(numberController.text);

              if (betAmount == null || betAmount <= 0 || number == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số hợp lệ!')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập!')),
                );
                return;
              }

              try {
                await _lotteryService.addComment(
                  username: user.displayName ?? 'Anonymous',
                  betAmount: betAmount,
                  number: number,
                );
                Navigator.pop(context);
                _loadData(); // Reload data
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi gửi bình luận: $e')),
                );
              }
            },
            child: const Text('Xác Nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Tương Lai Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,

      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBetDialog,
        backgroundColor: _isPortalOpen && !_hasCommented
            ? const Color(0x964CAF50)
            : Colors.grey,
        icon: const Icon(Icons.add_comment),
        label: const Text(
          'Đặt Cược',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        tooltip: 'Đặt cược và bình luận số',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lottery Result Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết Quả Xổ Số',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _lotteryResult == null
                      ? const Text(
                    'Chưa có kết quả. Vui lòng chờ admin quay số!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số trúng thưởng: ${_lotteryResult!.winningNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Người thắng: ${_lotteryResult!.winners.isEmpty ? 'Chưa có' : _lotteryResult!.winners.join(', ')}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(_lotteryResult!.timestamp)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phần thưởng: ${_lotteryResult!.rewardMultiplier}x coins cược',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh Sách Bình Luận (${_comments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _comments.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      '${comment.username}: Số ${comment.number}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Cược: ${comment.betAmount} coins',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      DateFormat('dd/MM HH:mm').format(comment.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}