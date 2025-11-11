import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryResultModel {
  final String id;
  final int winningNumber;
  final List<String> winners; // List of usernames
  final double rewardMultiplier;
  final DateTime timestamp;

  LotteryResultModel({
    required this.id,
    required this.winningNumber,
    required this.winners,
    required this.rewardMultiplier,
    required this.timestamp,
  });

  // Convert Firestore document to LotteryResultModel
  factory LotteryResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LotteryResultModel(
      id: doc.id,
      winningNumber: data['winningNumber'] as int,
      winners: List<String>.from(data['winners'] ?? []),
      rewardMultiplier: (data['rewardMultiplier'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert model to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'winningNumber': winningNumber,
      'winners': winners,
      'rewardMultiplier': rewardMultiplier,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}