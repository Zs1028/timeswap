import 'package:flutter/material.dart';
import '../../routes.dart'; // make sure this matches your actual path

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSignup(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.signup);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFF4D1);
    const orange = Color(0xFFF39C50);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: _currentPage > 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentPage > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: const [
                  _OnboardingPage1(),
                  _OnboardingPage2(),
                  _OnboardingPage3(),
                ],
              ),
            ),

            // 🔵 PAGE INDICATORS BELOW PAGEVIEW
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = _currentPage == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  width: isActive ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        isActive ? const Color(0xFFF39C50) : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),

            // bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _currentPage < 2
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _goToSignup(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _goToSignup(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- PAGE 1 ----------

class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // logo
          Image.asset(
            'assets/images/logo.png',
            height: 230, // slightly bigger
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          const Text(
            'Exchange Time, Not Money',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Help others with your skills and earn time credits to get help when you need it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- PAGE 2 ----------

class _OnboardingPage2 extends StatelessWidget {
  const _OnboardingPage2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/handshaking.png',
              height: 260, // bigger image
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'How It Works?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ------- Offer Your Skills -------
          const Text(
            'Offer Your Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share what you can help with.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.black12, // grey line
          ),
          const SizedBox(height: 16),

          // ------- Request Help -------
          const Text(
            'Request Help',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Get help from the community.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.black12, // grey line
          ),
          const SizedBox(height: 16),

          // ------- Earn & Spend -------
          const Text(
            'Earn & Spend Time Credits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Help others to earn time credits.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// ---------- PAGE 3 ----------

class _OnboardingPage3 extends StatelessWidget {
  const _OnboardingPage3();

  @override
  Widget build(BuildContext context) {
    const bulletTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600, // semi bold
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/community.png',
              height: 230, // bigger image
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Ready to Start?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bullet 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.check, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Browse available services',
                  style: bulletTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bullet 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.check, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Offer your skills',
                  style: bulletTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bullet 3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.check, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Start with 10 free time credits',
                  style: bulletTextStyle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.black12,
          ),
          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Join a community where everyone\'s time is valued equally!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
