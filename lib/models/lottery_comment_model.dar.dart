import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryCommentModel {
  final String id;
  final String userId;
  final String username;
  final int betAmount;
  final int number;
  final DateTime timestamp;

  LotteryCommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.betAmount,
    required this.number,
    required this.timestamp,
  });

  // Convert Firestore document to LotteryCommentModel
  factory LotteryCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LotteryCommentModel(
      id: doc.id,
      userId: data['userId'] as String,
      username: data['username'] as String,
      betAmount: data['betAmount'] as int,
      number: data['number'] as int,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert model to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'betAmount': betAmount,
      'number': number,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}