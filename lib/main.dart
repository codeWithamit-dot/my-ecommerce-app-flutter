// lib/main.dart

import 'package:flutter/material.dart'; 
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_ecommerce_app/screens/home_hub_screen.dart';
import 'firebase_options.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/auth/login_screen.dart';
import 'package:my_ecommerce_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
SupabaseClient get supabase => Supabase.instance.client;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bxotgimtdwejmypazpen.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4b3RnaW10ZHdlam15cGF6cGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MjE0NjksImV4cCI6MjA3MDE5NzQ2OX0.fgL4LLjnjNHMwBsWfE2HWr89FK60AiWINRqLLsPxYR0',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authStateSubscription;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      
      if (session == null) {
        // If there's a valid context, clear the provider
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
           Provider.of<UserRoleProvider>(context, listen: false).clearProfile();
        }
        await NotificationService.removeTokenOnLogout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        await _createProfileIfNeeded(session.user);
        
        // After profile is created/checked, fetch data and initialize services.
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          // ✅ FIX: `await` ke baad context istemal karne se pehle, usse ek local variable mein daal do.
          final userProvider = Provider.of<UserRoleProvider>(context, listen: false);
          await userProvider.fetchUserProfile();
          // ignore: use_build_context_synchronously
          await _notificationService.initialize(context);
        }
        
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  Future<void> _createProfileIfNeeded(User user) async {
    try {
      final response = await supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
      if (response == null) {
        debugPrint('Profile not found, creating one...');
        final userMetadata = user.userMetadata;
        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': userMetadata?['full_name'],
          'profile_picture_url': userMetadata?['avatar_url'],
        });
        debugPrint('Profile for ${user.id} created.');
      } else {
        debugPrint('Profile already exists.');
      }
    } catch (error) {
      debugPrint('Error creating profile: $error');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Store',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF267873)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF267873), foregroundColor: Colors.white),
      ),
      home: const Scaffold(body: Center(child: CircularProgressIndicator())), 
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeHubScreen(),
      },
    );
  }
}