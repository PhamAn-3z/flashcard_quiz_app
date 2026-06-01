import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_quiz_app/core/database/db_connection.dart';
import 'package:flashcard_quiz_app/providers/auth_provider.dart';
import 'package:flashcard_quiz_app/providers/notification_provider.dart';
import 'package:flashcard_quiz_app/providers/deck_provider.dart';
import 'package:flashcard_quiz_app/screens/login_screen.dart';
import 'package:flashcard_quiz_app/screens/main_navigation.dart';
import 'package:flashcard_quiz_app/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test database connection
  DbConnection db = DbConnection();
  await db.testCloudConnection();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nihongo Flashcard Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
