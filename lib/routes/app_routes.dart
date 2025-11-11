import 'package:flutter/material.dart';
import 'package:habit_tracker/views/admin/admin_articles_list_screen.dart';
import 'package:habit_tracker/views/admin/admin_menu_screen.dart';
import 'package:habit_tracker/views/friends/add_friend_screen.dart';
import 'package:habit_tracker/views/friends/friends_screen.dart';
import 'package:habit_tracker/views/futureportal/future_portal_screen.dart';
import 'package:habit_tracker/views/leaderboard/leaderboard_screen.dart';
import 'package:habit_tracker/views/main_screen.dart';
import 'package:habit_tracker/views/read_book/reading_challenge_screen.dart';
import 'package:habit_tracker/views/shop/inventory_screen.dart';
import 'package:habit_tracker/views/shop/shop_screen.dart';
import '../views/splash/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/home/home_screen.dart';
import '../views/habit/add_habit_screen.dart';
import '../views/habit/edit_habit_screen.dart';
import '../views/habit/habit_detail_screen.dart';
import '../views/profile/profile_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addHabit = '/add-habit';
  static const String editHabit = '/edit-habit';
  static const String habitDetail = '/habit-detail';
  static const String profile = '/profile';
  static const String leaderboard = '/leaderboard';
  static const String main = '/main';
  static const String shop = '/shop';
  static const String inventory = '/inventory';
  static const String addFriend = '/add_friend';
  static const String friends = '/friends';
  static const String reading = '/reading_screen';
  static const String admin = '/admin';
  static const String adminArticles = '/admin/articles';
  static const String readingChallenge = '/reading-challenge';
  static const String future = '/future-portal';

  // Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminArticles:
      // Lấy arguments từ settings
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => AdminArticlesListScreen(
            communityHabitId: args?['habitId'] ?? 'reading_challenge_001',
            communityHabitTitle: args?['title'] ?? 'Thử thách 7 ngày đọc sách',
          ),
        );

      case readingChallenge:
      // Lấy arguments từ settings
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ReadingChallengeScreen(
            communityHabitId: args?['habitId'] ?? 'reading_challenge_001',
            communityHabitTitle: args?['title'] ?? 'Thử thách đọc sách',
          ),
        );

      case future:
        return MaterialPageRoute(builder: (_) => const MyFuturePortalScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminMenuScreen());
      case addFriend:
        return MaterialPageRoute(builder: (_) => const AddFriendScreen());

      case friends:
        return MaterialPageRoute(builder: (_) => const FriendsScreen());

      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());

      case shop:
        return MaterialPageRoute(builder: (_) => const ShopScreen());

      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());

      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case addHabit:
        return MaterialPageRoute(builder: (_) => const AddHabitScreen());

      case editHabit:
        final habitId = settings.arguments as String?;
        if (habitId == null) {
          return _errorRoute('Habit ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => EditHabitScreen(habitId: habitId),
        );

      case habitDetail:
        final habitId = settings.arguments as String?;
        if (habitId == null) {
          return _errorRoute('Habit ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => HabitDetailScreen(habitId: habitId),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  // Error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Go back or navigate to home
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Named route navigation helpers
  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, home);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void navigateToAddHabit(BuildContext context) {
    Navigator.pushNamed(context, addHabit);
  }

  static void navigateToEditHabit(BuildContext context, String habitId) {
    Navigator.pushNamed(context, editHabit, arguments: habitId);
  }

  static void navigateToHabitDetail(BuildContext context, String habitId) {
    Navigator.pushNamed(context, habitDetail, arguments: habitId);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, profile);
  }

  // Logout and clear stack
  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }
}