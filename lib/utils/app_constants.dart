import 'package:flutter/material.dart';

class AppConstants {
  // Spacing
  static const double spacingExtraSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;

  // Corner Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusExtraSmall = 2.0; // Added for smaller radius
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // Text Styles (examples, can be expanded)
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
  );
}
