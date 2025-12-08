import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/welcome/welcome_page.dart';
import 'screens/welcome/welcome_page_2.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/profile/create_profile_page.dart';
import 'screens/home/home_page.dart';
import 'screens/need_help/filter_page.dart';
import 'screens/need_help/add_request_page.dart';
import 'screens/offer_help/add_offering_page.dart';
import 'screens/services/services_page.dart';
import 'screens/services/your_requests_page.dart';
import 'screens/credits/time_credit_details_page.dart';           // ⭐ add this
import 'screens/credits/transactions_history_page.dart';  // ⭐ add this
import 'screens/profile/profile_page.dart';
import 'screens/profile/settings_page.dart';
import 'screens/applications/my_applications_page.dart';


class AppRoutes {
  static const welcome = '/';
  static const welcome2 = '/welcome2';
  static const signup = '/signup';
  static const login = '/login';
  static const createProfile = '/create-profile';
  static const home = '/home';
  static const needHelpFilter = '/need-help/filter';
  static const addRequest = '/add-request';
  static const addOffering = '/offer-help/add';
  static const services = '/services';
  static const yourRequests = '/your-requests';
  static const timeCredits = '/timeCredits';                 // ⭐ added
  static const transactionHistory = '/transactionHistory';   // ⭐ added
  static const profile = '/profile';
  static const settings = '/settings';
  static const myApplications = '/myApplications';


  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return _buildRoute(const WelcomePage());

      case welcome2:
        return _buildRoute(const WelcomePage2());

      case signup:
        return _buildRoute(const SignupPage());

      case login:
        return _buildRoute(const LoginPage());

      // 🔒 require login
      case createProfile:
        return _buildRoute(const CreateProfilePage(), requireAuth: true);

      case home:
        return _buildRoute(const HomePage(), requireAuth: true);

      case needHelpFilter:
        return PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => const NeedHelpFiltersPage(),
        );

      case addRequest:
        return _buildRoute(const AddRequestPage(), requireAuth: true);

      case addOffering:
        return _buildRoute(const AddOfferingPage(), requireAuth: true);

      case services:
        return _buildRoute(const ServicesPage(), requireAuth: true);

      case yourRequests:
        return _buildRoute(const YourRequestsPage(), requireAuth: true);

      // ⭐ New pages
      case timeCredits:
        return _buildRoute(const TimeCreditPage(), requireAuth: true);

      case transactionHistory:
        return _buildRoute(const TransactionHistoryPage(), requireAuth: true);

      case AppRoutes.profile:
        return _buildRoute(const ProfilePage(), requireAuth: true);

      case AppRoutes.settings:
        return _buildRoute(const SettingsPage(), requireAuth: true);

      case AppRoutes.myApplications:
        return _buildRoute(const MyApplicationsPage(), requireAuth: true);

      // Default → fallback
      default:
        return _buildRoute(const WelcomePage());
    }
  }

  /// Helper: Optionally require FirebaseAuth
  static MaterialPageRoute _buildRoute(
    Widget page, {
    bool requireAuth = false,
  }) {
    if (requireAuth) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return MaterialPageRoute(builder: (_) => const LoginPage());
      }
    }
    return MaterialPageRoute(builder: (_) => page);
  }
}
