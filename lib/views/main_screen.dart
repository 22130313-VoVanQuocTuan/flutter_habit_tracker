import 'package:flutter/material.dart';
import 'package:habit_tracker/views/friends/friends_screen.dart';
import 'package:habit_tracker/views/habit/add_habit_screen.dart';
import 'package:habit_tracker/views/home/home_screen.dart';
import 'package:habit_tracker/views/leaderboard/leaderboard_screen.dart';
import 'package:habit_tracker/views/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LeaderboardScreen(),
    const Center(child: Text('Add Habit')), // placeholder
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // FAB: Push AddHabit modal
      _previousIndex = _currentIndex;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddHabitScreen()),
      ).then((_) {
        // Khi trở về, giữ nguyên tab trước
        setState(() {
          _currentIndex = _previousIndex;
        });
      });
    } else {
      // Chỉ đổi tab, KHÔNG push route
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Trang chủ', 0),
            _buildNavItem(Icons.leaderboard_outlined, Icons.leaderboard, 'Xếp hạng', 1),
            const SizedBox(width: 60), // space for FAB
            _buildNavItem(Icons.people_outline, Icons.people, 'Bạn bè', 3),
            _buildNavItem(Icons.person_outline, Icons.person, 'Tài khoản', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: isActive ? Colors.green[600] : Colors.grey[400]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? Colors.green[600] : Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _onTabTapped(2),
      child: const Icon(Icons.add_rounded, size: 36),
    );

  }
}
