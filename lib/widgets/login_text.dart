import 'package:flutter/material.dart';

class LoginText extends StatelessWidget {
  const LoginText({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(
            color: const Color(0xFF000000).withOpacity(0.46), // 46% black
            fontSize: 14,
          ),
          children: const [
            TextSpan(
              text: 'Login',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
