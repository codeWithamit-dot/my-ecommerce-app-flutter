// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_ecommerce_app/screens/home_hub_screen.dart';
import 'firebase_options.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/auth/splash_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;

      final session = data.session;
      final userRoleProvider = Provider.of<UserRoleProvider>(context, listen: false);

      if (session == null) {
        // ✅ FIX: Using the corrected function name from the upgraded provider
        userRoleProvider.clearProfile();
        NotificationService.removeTokenOnLogout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        await Future.wait([
          // ✅ FIX: Using the corrected function name from the upgraded provider
          userRoleProvider.fetchUserProfile(),
          NotificationService().initialize(),
        ]);
        
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
      title: 'E-Commerce App',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[600],
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeHubScreen(),
      },
    );
  }
}