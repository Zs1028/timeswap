import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'routes.dart';
import 'screens/welcome/welcome_page.dart';
import 'screens/home/home_page.dart';

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
    return MaterialApp(
      title: 'TimeSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // We no longer use initialRoute based on currentUser once.
      // Instead we listen to auth state changes in AuthGate.
      home: const AuthGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

/// This widget decides whether to show Welcome or Home
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking if Firebase is connecting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Not logged in → show welcome/onboarding
          return const WelcomePage();
        } else {
          // Logged in → go to Home
          return const HomePage();
        }
      },
    );
  }
}
