import 'package:flutter/material.dart';
import '../../../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCheckedIn;
  final VoidCallback onCheckIn;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCheckedIn,
    required this.onCheckIn,
    this.onTap,
  });

  Color _getColor() {
    try {
      return Color(int.parse(habit.color.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    // Ẩn hoặc vô hiệu hóa card nếu habit đã xóa mềm
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    habit.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (habit.description != null && habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          habit.frequency == 'daily' ? 'Hàng ngày' : 'Hàng tuần',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          habit.formattedReminderTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Check-in button
              Material(
                color: isCheckedIn ? Colors.green : color,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: !isCheckedIn && habit.isActive ? onCheckIn : null, // Vô hiệu hóa nếu đã check-in hoặc habit inactive
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCheckedIn ? Icons.check : Icons.check_box_outline_blank,
                      color: Colors.white,
                      size: 24,
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
