import 'package:flutter/material.dart';

class AppStyle {
  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFD4D8F3),
      Color(0xFF8D9EDB),
      Color(0xFFB59C4A),
    ],
    stops: [0.0, 0.56, 1.0],
  );

  static BoxDecoration pageDecoration = const BoxDecoration(
    gradient: gradient,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.92),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade300,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    ),
  );
}