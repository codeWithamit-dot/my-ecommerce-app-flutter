// lib/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/home_screen.dart';
import 'package:my_ecommerce_app/login_screen.dart';
import 'package:my_ecommerce_app/main.dart'; // supabase client ke liye

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Ye widget ko build hone ka time deta hai
    await Future.delayed(Duration.zero);
    
    // Safety check
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    
    // --- YEH HAI NAYA AUR AASAN LOGIC ---
    if (session != null) {
      // User logged in hai? Seedha HomeScreen bhejo.
      // Baaki sab kuch ab HomeScreen dekhegi.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // User logged in nahi hai? LoginScreen par bhejo.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }

    // <<<--- PURANA ROLE/PROFILE CHECKING KA SAARA LOGIC YAHAN SE HATA DIYA GAYA HAI ---<<<
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}