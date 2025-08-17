// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:my_ecommerce_app/main.dart'; // To access the supabase client

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // This function initializes the entire notification setup
  Future<void> initialize() async {
    // 1. Request Permission from the user (for iOS and modern Android)
    await _requestPermission();

    // 2. Get the unique device token (FCM Token)
    final fcmToken = await _getToken();

    // 3. Save the token to your Supabase 'profiles' table
    if (fcmToken != null) {
      _saveTokenToDatabase(fcmToken);
    }
    
    // 4. Set up a listener to save the token whenever it gets refreshed
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  // Request notification permission from the user
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  // Get the unique FCM token for this device
  Future<String?> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Save the FCM token to the current user's profile in Supabase
  void _saveTokenToDatabase(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
      
      debugPrint('FCM token saved to database successfully.');
    } catch (e) {
      debugPrint('Error saving FCM token to database: $e');
    }
  }

  // A function to remove the token on logout
  static Future<void> removeTokenOnLogout() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
        await supabase
        .from('profiles')
        .update({'fcm_token': null}) // Set the token to null
        .eq('id', userId);
      debugPrint('FCM token removed on logout.');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
}