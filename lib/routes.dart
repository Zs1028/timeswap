import 'package:flutter/material.dart';
import 'screens/welcome/welcome_page.dart';
import 'screens/welcome/welcome_page_2.dart';

class AppRoutes {
  static const welcome = '/';
  static const welcome2 = '/welcome2';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case welcome2:
        return MaterialPageRoute(builder: (_) => const WelcomePage2());
      default:      
        return MaterialPageRoute(builder: (_) => const WelcomePage());
    }
  }
}
