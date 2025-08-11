// lib/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
// Dono nayi screens ko import karein
import 'package:my_ecommerce_app/profile/create_buyer_profile_screen.dart';
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

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User is not logged in';
      
      await supabase.from('profiles').update({'role': role}).eq('id', user.id);

      if (mounted) {
        // --- LOGIC MEIN BADLAAV YAHAN HAI ---
        if (role == 'buyer') {
          // Buyer hai to Buyer form par bhejo
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CreateBuyerProfileScreen()),
            (route) => false,
          );
        } else if (role == 'seller') {
          // Seller hai to Seller form par bhejo
           Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CreateSellerProfileScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    // UI mein koi badlaav nahi hai, woh waisa hi rahega
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
                    Text( "One last step!", style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    const Text( "Please select your account type to continue.", textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => _updateUserRole('buyer'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text("I am a Buyer", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _updateUserRole('seller'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text("I am a Seller", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}