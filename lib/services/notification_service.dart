// lib/services/notification_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // `supabase` client ke liye
import '../screens/orders_manager_screen.dart'; // Example navigation target

// Yeh function top-level hona zaroori hai
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Background mein Firebase ko initialize karo
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    // `await` se pehle context se zaroori cheezein nikal lo
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await _requestPermission();

    final fcmToken = await _getToken();
    if (fcmToken != null) {
      await _saveTokenToDatabase(fcmToken);
    }
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
    
    // Background message handler ko main.dart mein set karna best practice hai
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    _setupListeners(navigator, scaffoldMessenger);
  }

  Future<void> _requestPermission() async {
    try {
      await _firebaseMessaging.requestPermission();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<String?> _getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('profiles').update({'fcm_token': token}).eq('id', userId);
      debugPrint('FCM token saved to database.');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
  
  static Future<void> removeTokenOnLogout() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('profiles').update({'fcm_token': null}).eq('id', userId);
      debugPrint('FCM token removed on logout.');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  void _setupListeners(NavigatorState navigator, ScaffoldMessengerState scaffoldMessenger) {
    // App jab khuli ho
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received!');
      if (message.notification != null && navigator.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${message.notification!.title ?? ''}: ${message.notification!.body ?? ''}'),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    });

    // App background se kholi jaaye
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened from background!');
      if (navigator.mounted) {
        _handleNotificationClick(navigator, message.data);
      }
    });
  }

  void _handleNotificationClick(NavigatorState navigator, Map<String, dynamic> data) {
    final String? screen = data['screen'];
    if (screen == 'orders' && navigator.mounted) {
      navigator.push(MaterialPageRoute(builder: (_) => const OrdersManagerScreen()));
    }
  }
}