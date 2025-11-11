import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int totalPoints;
  final int totalCoins;
  final int currentStreak;
  final int longestStreak;
  final int treeLevel;
  final DateTime? lastCheckinDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> friends;
  final int treeHealth; // 0-100 (100 = healthy, 0 = dead)
  final int daysWithoutCheckin;
  final List<String> diseases; // ['pest', 'drought', 'fungus']
  final bool isTreeDead;
  final DateTime? lastTreeHealthCheck;
  final Map<String, int> inventory; // Item ID -> Quantity
  final bool? isAdmin;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.totalPoints = 0,
    this.totalCoins = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.treeLevel = 0,
    this.lastCheckinDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.friends = const [],
    this.treeHealth = 100,
    this.daysWithoutCheckin = 0,
    this.diseases = const [],
    this.isTreeDead = false,
    this.lastTreeHealthCheck,
    this.inventory = const {},
    this.isAdmin,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      totalPoints: data['totalPoints'] ?? 0,
      totalCoins: data['totalCoins'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      treeLevel: data['treeLevel'] ?? 0,
      lastCheckinDate: data['lastCheckinDate'] != null
          ? (data['lastCheckinDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      friends: List<String>.from(data['friends'] ?? []),
      treeHealth: data['treeHealth'] ?? 100,
      daysWithoutCheckin: data['daysWithoutCheckin'] ?? 0,
      diseases: List<String>.from(data['diseases'] ?? []),
      isTreeDead: data['isTreeDead'] ?? false,
      lastTreeHealthCheck: data['lastTreeHealthCheck'] != null
          ? (data['lastTreeHealthCheck'] as Timestamp).toDate()
          : null,
      inventory: Map<String, int>.from(data['inventory'] ?? {}),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalPoints': totalPoints,
      'totalCoins': totalCoins,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'treeLevel': treeLevel,
      'lastCheckinDate': lastCheckinDate != null
          ? Timestamp.fromDate(lastCheckinDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'friends': friends,
      'treeHealth': treeHealth,
      'daysWithoutCheckin': daysWithoutCheckin,
      'diseases': diseases,
      'isTreeDead': isTreeDead,
      'lastTreeHealthCheck': lastTreeHealthCheck != null
          ? Timestamp.fromDate(lastTreeHealthCheck!)
          : null,
      'inventory': inventory,
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    int? totalPoints,
    int? totalCoins,
    int? currentStreak,
    int? longestStreak,
    int? treeLevel,
    DateTime? lastCheckinDate,
    List<String>? friends,
    int? treeHealth,
    int? daysWithoutCheckin,
    List<String>? diseases,
    bool? isTreeDead,
    DateTime? lastTreeHealthCheck,
    Map<String, int>? inventory,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      totalCoins: totalCoins ?? this.totalCoins,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      treeLevel: treeLevel ?? this.treeLevel,
      lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      friends: friends ?? this.friends,
      treeHealth: treeHealth ?? this.treeHealth,
      daysWithoutCheckin: daysWithoutCheckin ?? this.daysWithoutCheckin,
      diseases: diseases ?? this.diseases,
      isTreeDead: isTreeDead ?? this.isTreeDead,
      lastTreeHealthCheck: lastTreeHealthCheck ?? this.lastTreeHealthCheck,
      inventory: inventory ?? this.inventory,
      isAdmin: isTreeDead ?? this.isAdmin,
    );
  }

  String get treeImagePath {
    return 'assets/images/trees/tree_level_$treeLevel.png';
  }

  int get pointsToNextLevel {
    const levelsPoints = [0, 100, 300, 600, 1000];
    if (treeLevel >= levelsPoints.length - 1) return 0;
    return levelsPoints[treeLevel + 1] - totalPoints;
  }

  String get treeEmoji {
    if (isTreeDead) return '💀';
    if (treeHealth >= 80) return '🌲';
    if (treeHealth >= 60) return '🌳';
    if (treeHealth >= 40) return '🌿';
    if (treeHealth >= 20) return '🪴';
    return '🍂';
  }

  String get diseaseEmoji {
    if (diseases.isEmpty) return '';
    if (diseases.contains('pest')) return '🐛';
    if (diseases.contains('drought')) return '🏜️';
    if (diseases.contains('fungus')) return '🍄';
    return '🦠';
  }

  String getHealthColor() {
    if (treeHealth >= 80) return '#4CAF50'; // Green
    if (treeHealth >= 60) return '#8BC34A'; // Light Green
    if (treeHealth >= 40) return '#FFC107'; // Yellow
    if (treeHealth >= 20) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  String getTreeStatusMessage() {
    if (isTreeDead) {
      return '💀 Cây của bạn đã chết. Mua Elixir để hồi sinh!';
    }
    if (treeHealth >= 80) {
      return '😊 Cây của bạn khỏe mạnh và hạnh phúc!';
    } else if (treeHealth >= 60) {
      return '🙂 Cây của bạn ổn, nhưng cần chăm sóc.';
    } else if (treeHealth >= 40) {
      return '😟 Cây của bạn bị bệnh! Mua thuốc từ cửa hàng.';
    } else if (treeHealth >= 20) {
      return '😢 Cây của bạn rất bệnh! Cần cấp cứu ngay!';
    } else {
      return '💀 Cây của bạn sắp chết! Giúp nó ngay!';
    }
  }
}