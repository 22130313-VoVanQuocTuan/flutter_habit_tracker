import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:habit_tracker/models/shop_modal.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/tree_health_service.dart';

class ShopViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TreeHealthService _treeHealthService = TreeHealthService();

  UserModel? _user;
  List<ShopItem> _shopItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  List<ShopItem> get shopItems => _shopItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _setError('User not authenticated');
      return;
    }

    _setLoading(true);
    try {
      _user = await _firestoreService.getUserProfile(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user data: $e');
      _setLoading(false);
    }
  }

  Future<void> loadShopItems() async {
    _setLoading(true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('shop_items').get();
      _shopItems = snapshot.docs.map((doc) => ShopItem.fromFirestore(doc)).toList();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load shop items: $e');
      _setLoading(false);
    }
  }

  Future<bool> buyItem(ShopItem item) async {
    if (_user == null) {
      _setError('User not loaded');
      return false;
    }

    if (item.quantity <= 0) {
      _setError('Hết hàng: ${item.name}');
      return false;
    }

    if (_user!.totalCoins < item.cost) {
      _setError('Không đủ coins! Cần ${item.cost} nhưng chỉ có ${_user!.totalCoins}');
      return false;
    }

    try {
      final newInventory = Map<String, int>.from(_user!.inventory);
      newInventory[item.id] = (newInventory[item.id] ?? 0) + 1;

      final newUser = _user!.copyWith(
        totalCoins: _user!.totalCoins - item.cost,
        inventory: newInventory,
      );

      await FirebaseFirestore.instance
          .collection('shop_items')
          .doc(item.id)
          .update({'quantity': item.quantity - 1});

      await _firestoreService.updateUserProfile(newUser);
      _user = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to buy item: $e');
      return false;
    }
  }

   Future<bool> useItem(String itemId, String effectType, int effectValue) async {
    if (_user == null) {
      _setError('User not loaded');
      return false;
    }

    final inventory = Map<String, int>.from(_user!.inventory);
    if (inventory[itemId] == null || inventory[itemId]! <= 0) {
      _setError('Bạn không sở hữu ${itemId}');
      return false;
    }

    try {
      // Kiểm tra điều kiện cho thuốc
      if (effectType.startsWith('cure_')) {
        final diseaseType = effectType.replaceFirst('cure_', '');
        if (!_user!.diseases.contains(diseaseType)) {
          _setError('Cây không bị bệnh $diseaseType!');
          return false;
        }
      }

      // Giảm số lượng item trong kho
      inventory[itemId] = inventory[itemId]! - 1;
      if (inventory[itemId] == 0) {
        inventory.remove(itemId);
      }

      UserModel updatedUser = _user!.copyWith(inventory: inventory);

      // Áp dụng hiệu ứng của item
      if (effectType.startsWith('cure_')) {
        final diseaseType = effectType.replaceFirst('cure_', '');
        updatedUser = await _treeHealthService.useMedicine(updatedUser, diseaseType, effectValue);
      } else if (effectType == 'heal') {
        final newHealth = (updatedUser.treeHealth + effectValue).clamp(0, 100);
        final newDiseases = await _treeHealthService.assignDiseases (
          newHealth,
          updatedUser.daysWithoutCheckin,
          updatedUser.diseases,
        );
        updatedUser = updatedUser.copyWith(
          treeHealth: newHealth,
          diseases: newDiseases,
          lastTreeHealthCheck: DateTime.now(),
        );
      } else if (effectType == 'resurrect') {
        updatedUser = await _treeHealthService.resurrectTree(updatedUser);
      }

      // Lưu cập nhật vào Firestore
      await _firestoreService.updateUserProfile(updatedUser);
      await _treeHealthService.saveTreeHealth(updatedUser);

      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to use item: $e');
      return false;
    }
  }
  List<ShopItem> getItemsByCategory(String category) {
    if (category == 'medicine') {
      return _shopItems.where((item) => item.effectType.startsWith('cure_')).toList();
    } else if (category == 'fertilizer') {
      return _shopItems.where((item) => item.effectType == 'heal').toList();
    } else if (category == 'special') {
      return _shopItems.where((item) => item.effectType == 'resurrect').toList();
    }
    return _shopItems;
  }
}