import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class TreeHealthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kiểm tra sức khỏe cây mỗi ngày
  Future<UserModel> checkAndUpdateTreeHealth(UserModel user) async {
    final now = DateTime.now();
    final lastCheck = user.lastTreeHealthCheck ?? user.createdAt;
    final daysDiff = now.difference(lastCheck).inDays;

    if (daysDiff <= 0) return user; // No update if checked today

    // Calculate new health and days without check-in
    int newHealth = user.treeHealth;
    int newDaysWithoutCheckin = user.daysWithoutCheckin + daysDiff;

    // Decrease health: 5 points per day without check-in
    newHealth = (newHealth - (daysDiff * 5)).clamp(0, 100);

    // Chỉ định bệnh dựa trên tình trạng sức khỏe và số ngày không nhập viện
    List<String> newDiseases = await assignDiseases(newHealth, newDaysWithoutCheckin, user.diseases);

    // Set tree as dead if health reaches 0
    final isDead = newHealth <= 0;

    final updatedUser = user.copyWith(
      treeHealth: newHealth,
      daysWithoutCheckin: newDaysWithoutCheckin,
      diseases: newDiseases,
      isTreeDead: isDead,
      lastTreeHealthCheck: now,
    );

    // Save to Firestore
    await saveTreeHealth(updatedUser);
    return updatedUser;
  }
  // Assign diseases based on health and days without check-in
  Future<List<String>> assignDiseases(int treeHealth, int daysWithoutCheckin, List<String> currentDiseases) async {
    final random = Random();
    List<String> newDiseases = List.from(currentDiseases);

    // Clear diseases if health is high or tree is dead
    if (treeHealth >= 80 || treeHealth <= 0) {
      return [];
    }

    // Quy tắc phân công bệnh tật với xác suất
    const diseaseRules = {
      'pest': {'healthThreshold': 50, 'daysThreshold': 1, 'probability': 0.4},
      'drought': {'healthThreshold': 60, 'daysThreshold': 2, 'probability': 0.5},
      'fungus': {'healthThreshold': 40, 'daysThreshold': 1, 'probability': 0.3},
    };

    // Add new diseases based on rules
    for (var entry in diseaseRules.entries) {
      final disease = entry.key;
      final healthThreshold = entry.value['healthThreshold'] as int;
      final daysThreshold = entry.value['daysThreshold'] as int;
      final probability = entry.value['probability'] as double;

      if (treeHealth < healthThreshold &&
          daysWithoutCheckin >= daysThreshold &&
          !newDiseases.contains(disease) &&
          random.nextDouble() < probability) {
        newDiseases.add(disease);
      }
    }

    // Remove diseases if health improves (random chance)
    if (treeHealth >= 60) {
      if (newDiseases.contains('pest') && random.nextDouble() < 0.2) {
        newDiseases.remove('pest');
      }
      if (newDiseases.contains('fungus') && random.nextDouble() < 0.2) {
        newDiseases.remove('fungus');
      }
    }
    if (treeHealth >= 70 && newDiseases.contains('drought') && random.nextDouble() < 0.3) {
      newDiseases.remove('drought');
    }

    return newDiseases;
  }

  // Reset ngày không check-in (sau khi check-in thành công)
  Future<UserModel> onDailyCheckIn(UserModel user) async {
    // Cây hồi phục sức khỏe +10 khi check-in
    int newHealth = (user.treeHealth + 10).clamp(0, 100);

    // Reset ngày không check-in
    int newDaysWithoutCheckin = 0;

    // Đánh giá lại bệnh tật
    List<String> newDiseases = await assignDiseases(newHealth, newDaysWithoutCheckin, user.diseases);

    final updatedUser = user.copyWith(
      treeHealth: newHealth,
      daysWithoutCheckin: newDaysWithoutCheckin,
      diseases: newDiseases,
      isTreeDead: newHealth <= 0,
      lastTreeHealthCheck: DateTime.now(),
      lastCheckinDate: DateTime.now(),
    );

    // Save to Firestore
    await saveTreeHealth(updatedUser);
    return updatedUser;
  }

  // Sử dụng thuốc để chữa bệnh
  Future<UserModel> useMedicine(UserModel user, String diseaseType, int healAmount) async {
    List<String> newDiseases = List.from(user.diseases);
    newDiseases.removeWhere((d) => d == diseaseType);

    int newHealth = (user.treeHealth + healAmount).clamp(0, 100);

    final updatedUser = user.copyWith(
      treeHealth: newHealth,
      diseases: newDiseases,
      isTreeDead: newHealth <= 0,
      lastTreeHealthCheck: DateTime.now(),
    );

    // Save to Firestore
    await saveTreeHealth(updatedUser);
    return updatedUser;
  }

  // Hồi sinh cây (400 coins)
  Future<UserModel> resurrectTree(UserModel user) async {
    if (!user.isTreeDead) {
      throw Exception('Cây không bị chết');
    }

    final updatedUser = user.copyWith(
      treeHealth: 50,
      isTreeDead: false,
      diseases: [],
      daysWithoutCheckin: 0,
      lastTreeHealthCheck: DateTime.now(),
    );
    // Save to Firestore
    await saveTreeHealth(updatedUser);
    return updatedUser;
  }

  // Lưu trạng thái cây vào Firestore
  Future<void> saveTreeHealth(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).update({
        'treeHealth': user.treeHealth,
        'daysWithoutCheckin': user.daysWithoutCheckin,
        'diseases': user.diseases,
        'isTreeDead': user.isTreeDead,
        'lastTreeHealthCheck': Timestamp.fromDate(
          user.lastTreeHealthCheck ?? DateTime.now(),
        ),
        'lastCheckinDate': user.lastCheckinDate != null
            ? Timestamp.fromDate(user.lastCheckinDate!)
            : null,
      });
    } catch (e) {
      throw Exception('Error saving tree health: $e');
    }
  }
}