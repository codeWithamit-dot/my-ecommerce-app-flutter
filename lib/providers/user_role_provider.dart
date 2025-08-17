// lib/providers/user_role_provider.dart

import 'package:flutter/material.dart'; // ✅ FIX: Colon ":" was missing
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ FIX: 'with ChangeNotifier' was missing. This is essential for a provider.
class UserRoleProvider with ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  String? get role => _profile?['role'];
  String? get approvalStatus => _profile?['approval_status'];
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await Supabase.instance.client
        .from('profiles')
        .select() // Select everything
        .eq('id', user.id)
        .single();
        
      _profile = response;
      
    } catch (e) {
      _profile = null;
      debugPrint("Error fetching user profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
      _profile = null;
      notifyListeners();
  }
}