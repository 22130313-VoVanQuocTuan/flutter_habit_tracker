import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_tracker/views/friends/ChatScreen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _selectedTab = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bạn Bè',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showSearchAndSendRequestDialog(context),
            tooltip: 'Gửi lời mời kết bạn',
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          // Friends stats
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>?;
                var friendCount = (userData?['friends'] as List<dynamic>?)?.length ?? 0;

                return FutureBuilder<int>(
                  future: _getPendingRequestCount(),
                  builder: (context, reqSnapshot) {
                    int requestCount = reqSnapshot.data ?? 0;
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$friendCount', 'Bạn bè', Icons.people),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem('$requestCount', 'Lời mời', Icons.mail_outline),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Section tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTab('Bạn bè', _selectedTab == 'Bạn bè', () => setState(() => _selectedTab = 'Bạn bè')),
                  const SizedBox(width: 12),
                  _buildTab('Lời mời', _selectedTab == 'Lời mời', () => setState(() => _selectedTab = 'Lời mời')),
                ],
              ),
            ),
          ),

          // Friends list or friend requests
          _selectedTab == 'Lời mời'
              ? _buildFriendRequestsList()
              : _buildFriendsList(),
        ],
      ),
    );
  }

  Future<int> _getPendingRequestCount() async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('to', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.green[600]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        var friends = (userData?['friends'] as List<dynamic>?) ?? [];

        if (friends.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.green[300],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có bạn bè nào',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gửi lời mời kết bạn để cùng nhau\nxây dựng thói quen tốt!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showSearchAndSendRequestDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Gửi lời mời'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(friends[index]).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Đang tải...'));
                  }
                  final friendData = userSnapshot.data?.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[200],
                          backgroundImage: friendData['photoUrl'] != null
                              ? NetworkImage(friendData['photoUrl'])
                              : null,
                          child: friendData['photoUrl'] == null
                              ? Text(
                            friendData['displayName']?[0]?.toUpperCase() ?? 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                              : null,
                        ),
                        title: Text(
                          friendData['displayName'] ?? 'Không tên',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          friendData['email'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      friendId: friends[index],
                                      friendName: friendData['displayName'] ?? 'Không tên',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _showRemoveFriendDialog(context, friends[index]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            childCount: friends.length,
          ),
        );
      },
    );
  }

  Widget _buildFriendRequestsList() {
    var currentUserId = _auth.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('friendRequests')
          .where('to', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        var requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Không có lời mời kết bạn nào',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              var req = requests[index].data() as Map<String, dynamic>;
              var fromUserId = req['from'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(fromUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Đang tải...'));
                  }
                  var sender = userSnapshot.data!.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[200],
                          backgroundImage: sender['photoUrl'] != null
                              ? NetworkImage(sender['photoUrl'])
                              : null,
                          child: sender['photoUrl'] == null
                              ? Text(
                            sender['displayName']?[0]?.toUpperCase() ?? 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                              : null,
                        ),
                        title: Text(
                          sender['displayName'] ?? 'Không tên',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          sender['email'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: 'Chấp nhận',
                              onPressed: () => _acceptFriendRequest(requests[index].id, fromUserId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Từ chối',
                              onPressed: () => _declineFriendRequest(requests[index].id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            childCount: requests.length,
          ),
        );
      },
    );
  }

  void _showSearchAndSendRequestDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Gửi lời mời kết bạn'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          searchResults.clear();
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) async {
                    if (value.trim().isEmpty) {
                      setState(() {
                        searchResults.clear();
                      });
                      return;
                    }

                    setState(() {
                      isSearching = true;
                    });

                    try {
                      final currentUserId = _auth.currentUser!.uid;

                      // Tìm kiếm theo displayName
                      final nameResults = await _firestore
                          .collection('users')
                          .where('displayName', isGreaterThanOrEqualTo: value)
                          .where('displayName', isLessThan: value + 'z')
                          .get();

                      List<Map<String, dynamic>> results = [];
                      final currentUserFriends = await _getCurrentUserFriends();

                      for (var doc in nameResults.docs) {
                        if (doc.id != currentUserId) {
                          // Kiểm tra đã là bạn chưa hoặc đã gửi lời mời chưa
                          final hasRequest = await _hasExistingRequest(currentUserId, doc.id);

                          results.add({
                            'id': doc.id,
                            'displayName': doc['displayName'] ?? 'Không tên',
                            'email': doc['email'] ?? '',
                            'photoUrl': doc['photoUrl'],
                            'totalPoints': doc['totalPoints'] ?? 0,
                            'treeLevel': doc['treeLevel'] ?? 0,
                            'isFriend': currentUserFriends.contains(doc.id),
                            'hasRequest': hasRequest,
                          });
                        }
                      }

                      // Nếu không tìm thấy, tìm kiếm theo email
                      if (results.isEmpty) {
                        final emailResults = await _firestore
                            .collection('users')
                            .where('email', isEqualTo: value.toLowerCase())
                            .get();

                        for (var doc in emailResults.docs) {
                          if (doc.id != currentUserId) {
                            final hasRequest = await _hasExistingRequest(currentUserId, doc.id);

                            results.add({
                              'id': doc.id,
                              'displayName': doc['displayName'] ?? 'Không tên',
                              'email': doc['email'] ?? '',
                              'photoUrl': doc['photoUrl'],
                              'totalPoints': doc['totalPoints'] ?? 0,
                              'treeLevel': doc['treeLevel'] ?? 0,
                              'isFriend': currentUserFriends.contains(doc.id),
                              'hasRequest': hasRequest,
                            });
                          }
                        }
                      }

                      setState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } catch (e) {
                      setState(() {
                        isSearching = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (searchResults.isEmpty && controller.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Không tìm thấy kết quả',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else if (searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final isFriend = user['isFriend'] as bool;
                          final hasRequest = user['hasRequest'] as bool;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[200],
                              backgroundImage: user['photoUrl'] != null
                                  ? NetworkImage(user['photoUrl'])
                                  : null,
                              child: user['photoUrl'] == null
                                  ? Text(
                                user['displayName'][0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                                  : null,
                            ),
                            title: Text(user['displayName']),
                            subtitle: Text(
                              user['email'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isFriend
                                ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Đã kết bạn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : hasRequest
                                ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Đã gửi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : ElevatedButton.icon(
                              onPressed: () => _sendFriendRequest(context, user['id'], user['displayName']),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Gửi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _hasExistingRequest(String fromUserId, String toUserId) async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('from', isEqualTo: fromUserId)
          .where('to', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count! > 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _getCurrentUserFriends() async {
    try {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      return List<String>.from(data?['friends'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendFriendRequest(
      BuildContext context, String toUserId, String toUserName) async {
    try {
      final currentUserId = _auth.currentUser!.uid;

      // Gửi lời mời kết bạn
      await _firestore.collection('friendRequests').add({
        'from': currentUserId,
        'to': toUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi lời mời đến $toUserName')),
      );

      // Refresh dialog
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _acceptFriendRequest(String requestId, String fromUserId) async {
    try {
      var currentUserId = _auth.currentUser!.uid;

      // Cập nhật bạn bè của cả 2 bên
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayUnion([fromUserId]),
      });
      await _firestore.collection('users').doc(fromUserId).update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // Cập nhật trạng thái lời mời
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận kết bạn')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'declined',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối kết bạn')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showRemoveFriendDialog(BuildContext context, String friendId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bạn'),
        content: const Text('Bạn có chắc chắn muốn xóa bạn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _removeFriend(friendId);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;

      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bạn')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}