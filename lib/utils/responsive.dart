import 'package:flutter/material.dart';

/// Responsive utility for percentage-based sizing.
/// Ensures UI looks correct on all screen sizes (iPhone SE to Tablets).
class Responsive {
  /// Get height as percentage of screen height
  /// Example: Responsive.height(context, 0.06) = 6% of screen height
  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  /// Get width as percentage of screen width
  /// Example: Responsive.width(context, 0.8) = 80% of screen width
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Get font size scaled to screen width
  /// Example: Responsive.text(context, 0.05) = 5% of screen width
  static double text(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Get responsive padding/margin based on screen width
  static double padding(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Get responsive icon size based on screen width
  static double icon(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Check if the device is a tablet (width > 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Check if the device is a small phone (width < 360)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
