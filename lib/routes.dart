import 'package:flutter/material.dart';
import 'screens/welcome/welcome_page.dart';
import 'screens/welcome/welcome_page_2.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/profile/create_profile_page.dart';
import 'screens/home/home_page.dart';
import 'screens/need_help/filter_page.dart';
import 'screens/need_help/add_request_page.dart';
import 'screens/offer_help/add_offering_page.dart'; // next step
import 'screens/services/services_page.dart';
import 'screens/services/your_requests_page.dart';


class AppRoutes {
  static const welcome = '/';
  static const welcome2 = '/welcome2';
  static const signup = '/signup'; 
  static const login     = '/login';
  static const createProfile = '/create-profile';
  static const home = '/home';
  static const needHelp = '/need-help';
  static const needHelpFilter = '/need-help/filter';
  static const addRequest = '/add-request';
  static const offerHelp = '/offer-help';
  static const addOffering = '/offer-help/add';
  static const services = '/services';
  static const yourRequests = '/your-requests';


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
      case needHelpFilter:
        return PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => const NeedHelpFiltersPage(),);
      case addRequest:
        return MaterialPageRoute(builder: (_) => const AddRequestPage());
      case addOffering:
        return MaterialPageRoute(builder: (_) => const AddOfferingPage());
      case services:
        return MaterialPageRoute(builder: (_) => const ServicesPage());
      case yourRequests:
        return MaterialPageRoute(builder: (_) => const YourRequestsPage());
      default:      
        return MaterialPageRoute(builder: (_) => const WelcomePage());
    }
  }
}
