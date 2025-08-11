// lib/main.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart'; // Naya import
import 'package:provider/provider.dart'; // Naya import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://bxotgimtdwejmypazpen.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4b3RnaW10ZHdlam15cGF6cGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2MjE0NjksImV4cCI6MjA3MDE5NzQ2OX0.fgL4LLjnjNHMwBsWfE2HWr89FK60AiWINRqLLsPxYR0',
  );
  
  // App ko Provider se wrap kiya gaya hai
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppModeProvider(),
      child: const MyApp(),
    ),
  );
}

// Global supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[600],
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}