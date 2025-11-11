import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/lottery_comment_model.dar.dart';
import 'package:habit_tracker/models/lottery_result_model.dart';
import 'package:habit_tracker/services/lottery_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';


class AdminLotteryScreen extends StatefulWidget {
  const AdminLotteryScreen({super.key});

  @override
  State<AdminLotteryScreen> createState() => _AdminLotteryScreenState();
}

class _AdminLotteryScreenState extends State<AdminLotteryScreen> {
  final LotteryService _lotteryService = LotteryService();
  final _numberOfWinnersController = TextEditingController();
  final _rewardMultiplierController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  LotteryResultModel? _latestResult;

  @override
  void initState() {
    super.initState();
    _loadLatestResult();
  }

  Future<void> _loadLatestResult() async {
    try {
      final result = await _lotteryService.loadLatestResult();
      setState(() {
        _latestResult = result;
      });
    } catch (e) {
      print('Lỗi tải kết quả mới nhất: $e');
    }
  }

  Future<void> _runLottery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập để quay số!');
      }

      // Kiểm tra xem đã quay số trong tuần này chưa
      if (await _lotteryService.hasLotteryResultForCurrentWeek()) {
        throw Exception('Kỳ xổ số tuần này đã được quay! Vui lòng kiểm tra kết quả.');
      }

      final numberOfWinners = int.tryParse(_numberOfWinnersController.text);
      final rewardMultiplier = double.tryParse(_rewardMultiplierController.text);

      if (numberOfWinners == null || numberOfWinners <= 0) {
        throw Exception('Vui lòng nhập số lượng người trúng hợp lệ!');
      }
      if (rewardMultiplier == null || rewardMultiplier <= 0) {
        throw Exception('Vui lòng nhập hệ số thưởng hợp lệ!');
      }

      // Lấy tất cả bình luận
      final comments = await _lotteryService.loadComments();
      if (comments.isEmpty) {
        throw Exception('Không có bình luận nào để quay số!');
      }

      // Chọn ngẫu nhiên một số từ các bình luận
      final random = Random();
      final winningNumber = comments[random.nextInt(comments.length)].number;

      // Lấy danh sách người thắng
      final winners = await _lotteryService.getWinners(winningNumber);
      final winnerUsernames = winners
          .take(numberOfWinners)
          .map((comment) => comment.username)
          .toList();

      // Xác nhận trước khi quay số
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận quay số'),
          content: const Text('Bạn có chắc chắn muốn quay số xổ số? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Lưu kết quả xổ số
      await _lotteryService.saveLotteryResult(
        winningNumber: winningNumber,
        winners: winnerUsernames,
        rewardMultiplier: rewardMultiplier,
      );

      // Cộng coin cho người thắng
      for (var winner in winners.take(numberOfWinners)) {
        final reward = (winner.betAmount * rewardMultiplier).toInt();
        await FirebaseFirestore.instance.collection('users').doc(winner.userId).update({
          'coins': FieldValue.increment(reward),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quay số thành công! Số trúng: $winningNumber')),
        );
        await _loadLatestResult(); // Cập nhật kết quả mới nhất
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xóa bình luận tuần trước
  Future<void> _clearPreviousWeekComments() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận cũ'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả bình luận của các tuần trước?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _lotteryService.clearPreviousWeekComments();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bình luận tuần trước')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _numberOfWinnersController.dispose();
    _rewardMultiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quay Số Xổ Số'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kết quả xổ số tuần này',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _latestResult == null
                ? const Text(
              'Chưa có kết quả tuần này.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            )
                : Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số trúng: ${_latestResult!.winningNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Người thắng: ${_latestResult!.winners.isEmpty ? 'Chưa có' : _latestResult!.winners.join(', ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Hệ số thưởng: ${_latestResult!.rewardMultiplier}x',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(_latestResult!.timestamp)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Danh sách bình luận tuần này',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<LotteryCommentModel>>(
              future: _lotteryService.loadComments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Lỗi tải bình luận: ${snapshot.error}');
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Chưa có bình luận nào trong tuần này',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        title: Text('${comment.username}: Số ${comment.number}'),
                        subtitle: Text('Cược: ${comment.betAmount} coins'),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập thông tin quay số',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberOfWinnersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng người trúng',
                hintText: 'Nhập số lượng (ví dụ: 3)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rewardMultiplierController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Hệ số thưởng coin (X)',
                hintText: 'Nhập hệ số (ví dụ: 2.5)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runLottery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Quay Số',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearPreviousWeekComments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Xóa Bình Luận Cũ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}