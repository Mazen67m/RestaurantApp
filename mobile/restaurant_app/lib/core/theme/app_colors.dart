import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFE91E63); // Crimson/Pink as seen in buttons
  static const Color primaryLight = Color(0xFFFF5252);
  static const Color primaryDark = Color(0xFFC2185B);

  // Background Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF616161);

  // Input & Borders
  static const Color inputBackground = Color(0xFF2D2D2D);
  static const Color border = Color(0xFF3D3D3D);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);

  // Gradient
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2D1B20), // Dark reddish tint
      Color(0xFF121212),
    ],
  );
}
