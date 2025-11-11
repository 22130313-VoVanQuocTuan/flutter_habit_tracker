import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/habit_viewmodel.dart';
import '../../viewmodels/checkin_viewmodel.dart';


class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckinViewModel>().loadHabitCheckins(widget.habitId);
    });
  }

  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Thói Quen',style: TextStyle(fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Pop back to MainScreen
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-habit',
                arguments: widget.habitId,
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.delete_outline),
          //   onPressed: () => _showDeleteDialog(context),
          // ),
        ],
      ),
      body: Consumer2<HabitViewModel, CheckinViewModel>(
        builder: (context, habitVM, checkinVM, child) {
          final habit = habitVM.getHabitById(widget.habitId);

          if (habit == null) {
            return const Center(child: Text('Thói quen không tồn tại'));
          }

          final checkins = checkinVM.getHabitCheckins(widget.habitId);
          final streak = checkinVM.getHabitStreak(widget.habitId);
          final isCheckedInToday = habitVM.isCheckedInToday(widget.habitId);
          final color = _getColor(habit.color);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            habit.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        habit.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (habit.description != null &&
                          habit.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          habit.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Chuỗi',
                        '$streak days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Hoàn thành',
                        '${checkins.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Trạng thái',
                        isCheckedInToday ? 'Hoàn thành' : 'Chưa thực hiện',
                        isCheckedInToday ? Icons.done : Icons.pending,
                        isCheckedInToday ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),

                // Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Tần suất',
                            habit.frequency == 'daily' ? 'Hàng ngày' : 'Hàng tuần',
                            Icons.repeat,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Nhắc nhở',
                            habit.reminderEnabled
                                ? habit.formattedReminderTime
                                : 'Disabled',
                            Icons.access_time,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Ngày tạo',
                            '${habit.createdAt.day}/${habit.createdAt.month}/${habit.createdAt.year}',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Recent Check-ins
                if (checkins.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hoàn thành gần đây',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: checkins.length > 10 ? 10 : checkins.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final checkin = checkins[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.1),
                                  child: Text(
                                    habit.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                title: Text(checkin.formattedDate),
                                subtitle: Text(checkin.formattedTime),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stars,
                                      size: 16,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${checkin.pointsEarned}',
                                      style: TextStyle(
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<HabitViewModel>(
        builder: (context, viewModel, child) {
          final isCheckedIn = viewModel.isCheckedInToday(widget.habitId);

          if (isCheckedIn) {
            return FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: Color(0x932AA830),
              icon: const Icon(Icons.check),
              label: const Text('Hoàn thành'),
            );
          }

          return FloatingActionButton.extended(
            onPressed: () async {
              final success = await viewModel.checkInHabit(widget.habitId);
              if (success && mounted) {
                await context.read<CheckinViewModel>().loadHabitCheckins(widget.habitId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã hoàn thành!', ),
                    backgroundColor: Color(0x932AA830),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Hoàn thành'),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thói quen'),
        content: const Text(
          'Bạn chắc chắn muốn xóa thói quen này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<HabitViewModel>().deleteHabit(widget.habitId);
              if (context.mounted) {
                Navigator.pop(context); // Đóng dialog
                if (success) {
                  Navigator.pop(context); // Quay về màn hình chính
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa thói quen thành công'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<HabitViewModel>().errorMessage ?? 'Lỗi không xác định'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}