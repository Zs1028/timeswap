import 'package:flutter/material.dart';

class ClockLogo extends StatelessWidget {
  const ClockLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',  // 👈 your logo path here
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
