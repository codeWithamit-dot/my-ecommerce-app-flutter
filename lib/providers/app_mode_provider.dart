// lib/providers/app_mode_provider.dart

import 'package:flutter/material.dart';

enum AppMode { buying, selling }

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.buying;

  AppMode get mode => _mode;

  void switchTo(AppMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  // ✅ FIX: Logout ke liye naya function yahan add kiya gaya hai
  // Yeh app mode ko wapas default (buying) par set kar dega.
  void resetMode() {
    _mode = AppMode.buying;
    // Yahan notifyListeners() call karne ki zaroorat nahi hai
    // kyunki iske baad waise bhi logout ho jaayega aur screen badal jayegi.
  }
}