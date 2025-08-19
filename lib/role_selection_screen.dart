// lib/role_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
// Dono nayi screens ko import karein
import 'package:my_ecommerce_app/profile/create_buyer_profile_screen.dart';
// ✅ FIX: Sahi file ko import kiya gaya
import 'package:my_ecommerce_app/profile/create_seller_profile_screen.dart';


class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _updateUserRole(String role) async {
    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User is not logged in';
      
      await supabase.from('profiles').update({'role': role}).eq('id', user.id);

      if (!mounted) return;

      if (role == 'buyer') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CreateBuyerProfileScreen()),
          (route) => false,
        );
      } else if (role == 'seller') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CreateSellerProfileScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text("Failed to set role: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text( "One last step!", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    const Text( "Please select your account type to continue.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () => _updateUserRole('buyer'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      label: const Text("I am a Buyer", style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.storefront_outlined),
                      onPressed: () => _updateUserRole('seller'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      label: const Text("I am a Seller", style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}