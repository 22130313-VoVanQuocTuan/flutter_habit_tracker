import 'package:cloud_firestore/cloud_firestore.dart';

class CheckinModel {
  final String id;
  final String userId;
  final String habitId;
  final DateTime checkinDate;
  final int pointsEarned;
  final int coinsEarned;
  final int streakCount;
  final DateTime createdAt;

  CheckinModel({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.checkinDate,
    this.pointsEarned = 10,
    this.coinsEarned = 10,
    this.streakCount = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Firestore -> Model
  factory CheckinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckinModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      habitId: data['habitId'] ?? '',
      checkinDate: data['checkinDate'] != null
          ? (data['checkinDate'] as Timestamp).toDate()
          : DateTime.now(),
      pointsEarned: data['pointsEarned'] ?? 10,
      coinsEarned: data['coinsEarned'] ?? 10,
      streakCount: data['streakCount'] ?? 1,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Model -> Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'habitId': habitId,
      'checkinDate': Timestamp.fromDate(checkinDate),
      'pointsEarned': pointsEarned,
      'coinsEarned': coinsEarned,
      'streakCount': streakCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Get date only (without time)
  DateTime get dateOnly {
    return DateTime(
      checkinDate.year,
      checkinDate.month,
      checkinDate.day,
    );
  }

  // Check if checked in today
  bool isToday() {
    final now = DateTime.now();
    return checkinDate.year == now.year &&
        checkinDate.month == now.month &&
        checkinDate.day == now.day;
  }

  // Check if checked in on specific date
  bool isOnDate(DateTime date) {
    return checkinDate.year == date.year &&
        checkinDate.month == date.month &&
        checkinDate.day == date.day;
  }

  // Get formatted date
  String get formattedDate {
    return '${checkinDate.day}/${checkinDate.month}/${checkinDate.year}';
  }

  // Get formatted time
  String get formattedTime {
    final hour = checkinDate.hour.toString().padLeft(2, '0');
    final minute = checkinDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Copy with method
  CheckinModel copyWith({
    String? userId,
    String? habitId,
    DateTime? checkinDate,
    int? pointsEarned,
    int? coinsEarned,
    int? streakCount,
  }) {
    return CheckinModel(
      id: id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      checkinDate: checkinDate ?? this.checkinDate,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt,
    );
  }
}