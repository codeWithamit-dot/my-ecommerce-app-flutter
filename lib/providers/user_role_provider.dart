// lib/providers/user_role_provider.dart

import 'package:flutter/material.dart';
// ✅ FIX: "package:" import ko relative path se badal diya gaya hai.
import '../main.dart'; // supabase client ke liye

class UserRoleProvider extends ChangeNotifier {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  bool get isLoading => _isLoading;
  String? get role => _userProfile?['role'];
  // ✅ FIX: Ek chhota sa typo tha yahan, `_user_profile` ko `_userProfile` kar diya hai.
  String? get fullName => _userProfile?['full_name'];
  String? get approvalStatus => _userProfile?['seller_status'];
  Map<String, dynamic>? get userProfile => _userProfile;
  
  UserRoleProvider() {
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _userProfile = null;
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _userProfile = data;

    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateRole(String newRole) {
    if (_userProfile != null) {
      _userProfile!['role'] = newRole;
      notifyListeners();
    }
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }

  void updateLocalProfile(Map<String, dynamic> updates) {
    if (_userProfile != null) {
      _userProfile!.addAll(updates);
      notifyListeners();
    }
  }
}