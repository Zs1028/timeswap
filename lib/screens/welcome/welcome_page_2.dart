import 'package:flutter/material.dart';
import 'widgets/clock_logo.dart';
import '../../widgets/login_text.dart';   // keep this


class WelcomePage2 extends StatelessWidget {
  const WelcomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4D1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // center vertically
            children: [
              const ClockLogo(),
              const SizedBox(height: 16),
              const Text(
                'Give time. Get time.\nEveryone’s time matters',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Offer or request help, share your time,\nand earn time credits in return.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('Get Started tapped');
                    // later: Navigator.pushNamed(context, AppRoutes.signup);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LoginText( // use the widget instead of _buildLoginText()
                onTap: () {
                  debugPrint('Login tapped');
                  // later: Navigator.pushNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
