import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TimeSwapApp());
}

class TimeSwapApp extends StatelessWidget {
  const TimeSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If user already logged in > go directly to home
    final user = FirebaseAuth.instance.currentUser;
    final initialRoute =
        user == null ? AppRoutes.welcome : AppRoutes.home;

    return MaterialApp(
      title: 'TimeSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
