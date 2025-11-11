import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteUser(String userId, String userEmail) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản: $userEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Lấy thông tin người dùng để lấy danh sách bạn bè
                final userDoc = await _firestore.collection('users').doc(userId).get();
                if (userDoc.exists) {
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final friends = List<String>.from(userData['friends'] ?? []);

                  // Xóa ID của người dùng bị xóa khỏi danh sách friends của từng bạn
                  final batch = _firestore.batch();
                  for (String friendId in friends) {
                    batch.update(_firestore.collection('users').doc(friendId), {
                      'friends': FieldValue.arrayRemove([userId]),
                    });
                  }

                  // Xóa tài liệu người dùng
                  batch.delete(_firestore.collection('users').doc(userId));

                  // Commit batch
                  await batch.commit();

                  // (Tùy chọn) Xóa các yêu cầu bạn bè liên quan
                  await _firestore.collection('friendRequests')
                      .where('from', isEqualTo: userId)
                      .get()
                      .then((snapshot) {
                    for (var doc in snapshot.docs) {
                      doc.reference.delete();
                    }
                  });
                  await _firestore.collection('friendRequests')
                      .where('to', isEqualTo: userId)
                      .get()
                      .then((snapshot) {
                    for (var doc in snapshot.docs) {
                      doc.reference.delete();
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xóa tài khoản thành công')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tài khoản không tồn tại')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm email hoặc tên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('isAdmin', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Không có tài khoản người dùng'),
                  );
                }

                var users = snapshot.data!.docs
                    .where((doc) {
                  try {
                    final email = (doc.data() as Map?)?['email'] ?? '';
                    final name = (doc.data() as Map?)?['displayName'] ?? '';
                    final emailStr = email.toString().toLowerCase();
                    final nameStr = name.toString().toLowerCase();
                    return emailStr.contains(_searchQuery) ||
                        nameStr.contains(_searchQuery);
                  } catch (e) {
                    return false;
                  }
                })
                    .toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy tài khoản phù hợp'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user.id;
                    final email = user['email'] ?? 'N/A';
                    final name = user['displayName'] ?? 'Không có tên';
                    final createdAt = user['createdAt'] as Timestamp?;
                    final formattedDate = createdAt != null
                        ? createdAt.toDate().toString().split('.')[0]
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $email'),
                            Text('Ngày tạo: $formattedDate'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(userId, email),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}