import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AddFriendViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> searchResults = [];
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String currentUserId;

  AddFriendViewModel({required this.currentUserId});

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      errorMessage = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Tìm kiếm theo displayName (username) hoặc email
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .get();

      List<UserModel> results = [];

      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          results.add(UserModel.fromFirestore(doc));
        }
      }

      // Nếu không tìm thấy theo username, tìm theo email
      if (results.isEmpty) {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: query.toLowerCase())
            .get();

        for (var doc in emailQuery.docs) {
          if (doc.id != currentUserId) {
            results.add(UserModel.fromFirestore(doc));
          }
        }
      }

      searchResults = results;
      if (results.isEmpty) {
        errorMessage = 'Không tìm thấy người dùng nào';
      }
    } catch (e) {
      errorMessage = 'Lỗi tìm kiếm: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFriend(String friendId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      final friendRef = _firestore.collection('users').doc(friendId);

      // Lấy dữ liệu hiện tại của cả hai người dùng
      final currentUserDoc = await currentUserRef.get();
      final friendDoc = await friendRef.get();

      if (!currentUserDoc.exists || !friendDoc.exists) {
        throw Exception('Người dùng không tồn tại');
      }

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final friendData = friendDoc.data() as Map<String, dynamic>;

      List<String> currentUserFriends =
      List<String>.from(currentUserData['friends'] ?? []);
      List<String> friendFriends =
      List<String>.from(friendData['friends'] ?? []);

      // Kiểm tra xem đã là bạn chưa
      if (currentUserFriends.contains(friendId)) {
        errorMessage = 'Bạn đã là bạn của người dùng này';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Thêm bạn theo chiều hai hướng
      currentUserFriends.add(friendId);
      friendFriends.add(currentUserId);

      await currentUserRef.update({'friends': currentUserFriends});
      await friendRef.update({'friends': friendFriends});

      successMessage = 'Đã kết bạn thành công!';

      // Loại bỏ người dùng khỏi danh sách kết quả
      searchResults.removeWhere((user) => user.id == friendId);

      isLoading = false;
      notifyListeners();

      // Xóa thông báo thành công sau 2 giây
      await Future.delayed(const Duration(seconds: 2));
      successMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Lỗi kết bạn: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    searchResults = [];
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}