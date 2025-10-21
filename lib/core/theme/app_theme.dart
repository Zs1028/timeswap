import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF39C50)),
    scaffoldBackgroundColor: const Color(0xFFFFF4D1), // your light yellow
    fontFamily: 'Inter', // if you haven't added the font, Flutter will fall back safely
  );
}
