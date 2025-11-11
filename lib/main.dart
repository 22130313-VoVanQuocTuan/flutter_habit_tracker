import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habit_tracker/routes/app_routes.dart';
import 'package:habit_tracker/viewmodels/checkin_viewmodel.dart';
import 'package:habit_tracker/viewmodels/leader_board_viewmodel.dart';
import 'package:habit_tracker/viewmodels/reading_challenge_viewmodel.dart';
import 'package:habit_tracker/viewmodels/shop_viewmodel.dart';
import 'package:provider/provider.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/habit_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Notifications
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  await NotificationService().requestNotificationPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HabitViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CheckinViewModel()),
        ChangeNotifierProvider(create: (_) => LeaderboardViewModel()),
        ChangeNotifierProvider(create: (_) => ShopViewModel()),
        ChangeNotifierProvider(create: (_) => ReadingChallengeViewModel()),

      ],
      child: MaterialApp(
        title: 'Theo Dõi Thói Quen',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          scaffoldBackgroundColor: Colors.lightGreen[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0x932AA830),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash, // Sử dụng hằng số từ AppRoutes
        onGenerateRoute: AppRoutes.generateRoute, // Sử dụng generateRoute từ AppRoutes
      ),
    );
  }
}