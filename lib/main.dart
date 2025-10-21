import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes.dart';

void main() => runApp(const TimeSwapApp());

class TimeSwapApp extends StatelessWidget {
  const TimeSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeSwap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
