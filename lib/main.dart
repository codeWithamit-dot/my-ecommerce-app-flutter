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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bxotgimtdwejmypazpen.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4b3RnaW10ZHdlam15cGF6cGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MjE0NjksImV4cCI6MjA3MDE5NzQ2OX0.fgL4LLjnjNHMwBsWfE2HWr89FK60AiWINRqLLsPxYR0',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  // =========== ⭐️ AAPKE TABLE KE HISAB SE UPDATED FUNCTION ================
  Future<void> _createProfileIfNeeded(User user) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Profile nahi mili, nayi profile bana raha hoon...');
        
        final userMetadata = user.userMetadata;
        final fullName = userMetadata?['full_name'];
        final avatarUrl = userMetadata?['avatar_url']; // Google se 'avatar_url' hi milta hai

        // Sirf woh columns insert karo jo zaroori hain aur table mein hain
        await supabase.from('profiles').insert({
          'id': user.id, // Primary Key - Zaroori
          'full_name': fullName, // Naam, agar Google se mila
          
          // ⭐️ FIX #1: Column ka naam `profile_picture_url` kar diya
          'profile_picture_url': avatarUrl,

          // ⭐️ FIX #2: `email` wala column hata diya kyunki woh table mein nahi hai
        });

        debugPrint('Profile for user ${user.id} successfully ban gayi!');
      } else {
        debugPrint('Profile pehle se hai.');
      }
    } catch (error) {
      debugPrint('Profile check/create karte waqt error: $error');
    }
  }
  // =========================================================================

  @override
  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final session = data.session;
      final userRoleProvider = Provider.of<UserRoleProvider>(context, listen: false);

      if (session == null) {
        userRoleProvider.clearProfile();
        NotificationService.removeTokenOnLogout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        await _createProfileIfNeeded(session.user);
        await userRoleProvider.fetchUserProfile();
        await NotificationService().initialize();
        
        if (!mounted) return;
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF267873),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Scaffold(backgroundColor: Color(0xFFE0F7F5), body: Center(child: CircularProgressIndicator())),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeHubScreen(),
      },
    );
  }
}