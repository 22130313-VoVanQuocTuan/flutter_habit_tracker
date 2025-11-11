import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String frequency; // 'daily' or 'weekly'
  final DateTime reminderTime;
  final bool reminderEnabled;
  final String color; // Hex color code
  final String icon; // Emoji or icon name
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.frequency = 'daily',
    required this.reminderTime,
    this.reminderEnabled = true,
    this.color = '#4CAF50',
    this.icon = '🌱',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory HabitModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Document ${doc.id} has no data");
    }

    return HabitModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      frequency: data['frequency'] ?? 'daily',
      reminderTime: (data['reminderTime'] is Timestamp)
          ? (data['reminderTime'] as Timestamp).toDate()
          : DateTime.now(),
      reminderEnabled: data['reminderEnabled'] ?? true,
      color: data['color'] ?? '#4CAF50',
      icon: data['icon'] ?? '🌱',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'frequency': frequency,
      'reminderTime': Timestamp.fromDate(reminderTime),
      'reminderEnabled': reminderEnabled,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method
  HabitModel copyWith({
    String? title,
    String? description,
    String? frequency,
    DateTime? reminderTime,
    bool? reminderEnabled,
    String? color,
    String? icon,
    bool? isActive,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Check if should remind today
  bool shouldRemindToday() {
    if (!reminderEnabled) return false;
    final now = DateTime.now();
    if (frequency == 'daily') return true;
    // Weekly: check if today matches reminder day
    return now.weekday == reminderTime.weekday;
  }

  // Get formatted reminder time
  String get formattedReminderTime {
    final hour = reminderTime.hour.toString().padLeft(2, '0');
    final minute = reminderTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}