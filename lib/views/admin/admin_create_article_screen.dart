import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCreateArticleScreen extends StatefulWidget {
  final String communityHabitId;
  final String communityHabitTitle;

  const AdminCreateArticleScreen({
    super.key,
    required this.communityHabitId,
    required this.communityHabitTitle,
  });

  @override
  State<AdminCreateArticleScreen> createState() => _AdminCreateArticleScreenState();
}

class _AdminCreateArticleScreenState extends State<AdminCreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _minCoinController = TextEditingController(text: '50');
  final _maxCoinController = TextEditingController(text: '200');
  final _minReadingTimeController = TextEditingController(text: '300');

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _minCoinController.dispose();
    _maxCoinController.dispose();
    _minReadingTimeController.dispose();
    super.dispose();
  }

  Future<void> _createArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('readingArticles').add({
        'communityHabitId': widget.communityHabitId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'minCoin': int.parse(_minCoinController.text),
        'maxCoin': int.parse(_maxCoinController.text),
        'minReadingTime': int.parse(_minReadingTimeController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo bài đọc thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _titleController.clear();
      _contentController.clear();
      _minCoinController.text = '50';
      _maxCoinController.text = '200';
      _minReadingTimeController.text = '300';

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Bài Đọc Mới'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thói quen:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.communityHabitTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề bài đọc',
                  hintText: 'Ví dụ: Kỹ năng quản lý thời gian',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Nội dung bài đọc',
                  hintText: 'Nhập nội dung bài đọc...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reading time field
              TextFormField(
                controller: _minReadingTimeController,
                decoration: InputDecoration(
                  labelText: 'Thời gian đọc (giây)',
                  hintText: '300 (5 phút)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập thời gian';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Min coin
              TextFormField(
                controller: _minCoinController,
                decoration: InputDecoration(
                  labelText: 'Coin tối thiểu',
                  hintText: '50',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập coin tối thiểu';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max coin
              TextFormField(
                controller: _maxCoinController,
                decoration: InputDecoration(
                  labelText: 'Coin tối đa',
                  hintText: '200',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập coin tối đa';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Phải là số';
                  }
                  final maxCoin = int.parse(value!);
                  final minCoin = int.parse(_minCoinController.text);
                  if (maxCoin < minCoin) {
                    return 'Coin tối đa phải >= coin tối thiểu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createArticle,
                  icon: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Đang tạo...' : 'Tạo bài đọc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}