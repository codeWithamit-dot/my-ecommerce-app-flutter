// lib/providers/app_mode_provider.dart
import 'package:flutter/material.dart';

// App ke do modes honge
enum AppMode { buying, selling }

class AppModeProvider with ChangeNotifier {
  AppMode _currentMode = AppMode.buying; // By default, user buyer hota hai

  AppMode get mode => _currentMode;

  void switchTo(AppMode newMode) {
    if (_currentMode != newMode) {
      _currentMode = newMode;
      notifyListeners(); // UI ko update karne ke liye signal bhejta hai
    }
  }
}