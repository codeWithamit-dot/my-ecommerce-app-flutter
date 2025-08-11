// app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Yeh ek static method hai taaki isse bina object banaye use kar sakein
  static ThemeData get lightTheme { 
    return ThemeData(
      // 1. Primary Colors
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,

      // 2. Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo, // Button ka background color
          foregroundColor: Colors.white, // Button ke text ka color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      
      // 3. Text Field Styles
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),

      // ...aur bhi bohot kuch! (AppBar theme, Text theme, etc.)
    );
  }
}