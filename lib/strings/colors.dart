import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Primary Palette ---
  /// The main background and accent color for the app (Hex: 0C1B46).
  static const Color primaryBlue = Color(0xFF0C1B46);

  /// The background color for cards and other elevated surfaces (Hex: FFFFFF).
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// The color for primary text elements (Hex: 121212).
  static const Color primaryText = Color(0xFF121212);

  /// The color for secondary or less important text (Hex: 898989).
  static const Color secondaryText = Color(0xFF898989);

  /// A general, light background color for pages.
  static const Color pageBackground = Color(0xFFF5F5F7);

  // --- Accent & Highlight Colors ---
  /// A dark navy accent color from the palette.
  static const Color darkNavy = Color(0xFF012A4A);

  /// A dark teal accent color from the palette.
  static const Color darkTeal = Color(0xFF013A63);

  /// A greenish-teal accent color from the palette.
  static const Color greenishTeal = Color(0xFF00A896);

  // --- Gradient Palette ---
  /// The darkest blue shade in the gradient palette.
  static const Color gradientDarkBlue = Color(0xFF2A3B8F);

  /// The middle purple shade in the gradient palette.
  static const Color gradientPurple = Color(0xFF4A4E9B);

  /// The lighter purple shade in the gradient palette.
  static const Color gradientLightPurple = Color(0xFF8C88C4);

  /// The lightest lavender shade in the gradient palette.
  static const Color gradientLavender = Color(0xFFC1C0E1);

  /// A coral accent color for highlights and CTAs.
  static const Color accentCoral = Color(0xFFFF6B6B);

  /// Alias for backward compatibility
  static const Color accentOrange = accentCoral;
}
