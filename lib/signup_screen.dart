import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/home_screen.dart'; // HomeScreen ke liye

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Email/Password se Signup ka function
  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Passwords do not match!'),
          backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'username': _usernameController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Success! Please check your email for verification.'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  // ---- GOOGLE SIGN-IN KA NAYA FUNCTION (signup screen ke liye) ----
  // Hum ise signup ki jagah seedha signin hi karwa denge
  Future<void> _signInWithGoogle() async {
    try {
          await supabase.auth.signInWithOAuth(OAuthProvider.google);
      
      // Agar user login ho gaya hai, to use seedha Home screen par bhej do
      if(supabase.auth.currentUser != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
      
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Google Sign-In Failed: ${e.message}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center( // Center widget
        child: ConstrainedBox( // Max width
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            shrinkWrap: true,
            children: [
              const Text('Create Your Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
          
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder())),
              const SizedBox(height: 20),
          
              ElevatedButton(onPressed: _signUp, child: const Text('Sign Up')),

              //--------- GOOGLE SIGN-IN KA UI SECTION ----------
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 10),
              
              ElevatedButton.icon(
                onPressed: _signInWithGoogle, 
                icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 1,
                  side: const BorderSide(color: Colors.grey)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}