import 'package:flutter/material.dart';
import 'screens/welcome/welcome_page.dart';
import 'screens/welcome/welcome_page_2.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/profile/create_profile_page.dart';
import 'screens/home/home_page.dart';
import 'screens/need_help/need_help_page.dart';
import 'screens/need_help/filter_page.dart';


class AppRoutes {
  static const welcome = '/';
  static const welcome2 = '/welcome2';
  static const signup = '/signup'; 
  static const login     = '/login';
  static const createProfile = '/create-profile';
  static const home = '/home';
  static const needHelp = '/need-help';
  static const needHelpFilter = '/need-help/filter';


  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case welcome2:
        return MaterialPageRoute(builder: (_) => const WelcomePage2());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case createProfile:
        return MaterialPageRoute(builder: (_) => const CreateProfilePage());
      case home: 
        return MaterialPageRoute(builder: (_) => const HomePage());
      case needHelp:
        return MaterialPageRoute(builder: (_) => const NeedHelpPage());
      case needHelpFilter:
        return PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => const NeedHelpFiltersPage(),);
      default:      
        return MaterialPageRoute(builder: (_) => const WelcomePage());
    }
  }
}
