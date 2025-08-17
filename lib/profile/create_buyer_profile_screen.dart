// lib/profile/create_buyer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateBuyerProfileScreen extends StatefulWidget {
  const CreateBuyerProfileScreen({super.key});
  @override
  State<CreateBuyerProfileScreen> createState() =>
      _CreateBuyerProfileScreenState();
}

class _CreateBuyerProfileScreenState extends State<CreateBuyerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'full_name': TextEditingController(),
    'phone': TextEditingController(),
    'shipping_address_line1': TextEditingController(),
    'shipping_address_line2': TextEditingController(),
    'shipping_city': TextEditingController(),
    'shipping_state': TextEditingController(),
    'shipping_pincode': TextEditingController(),
  };

  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'is_buyer_profile_complete': true,
      };

      // Lint-free for loop
      for (final entry in _controllers.entries) {
        updates[entry.key] = entry.value.text.trim();
      }

      await supabase
          .from('profiles')
          .update(updates)
          .eq('id', supabase.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Lint-free for loop
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String key, String label, {bool isOptional = false}) {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        hintText: isOptional ? 'Optional' : '',
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (!isOptional && v!.trim().isEmpty) return '$label is required';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Buyer Profile'),
        backgroundColor: const Color(0xFF267873),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE0F7F5), // Light background for the form
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Personal Information'),
                _buildTextField('full_name', 'Your Full Name'),
                const SizedBox(height: 12),
                _buildTextField('phone', 'Your Contact Number'),
                _buildSectionHeader('Default Shipping Address'),
                _buildTextField(
                    'shipping_address_line1', 'House No, Building, Street'),
                const SizedBox(height: 12),
                _buildTextField('shipping_address_line2', 'Area, Landmark',
                    isOptional: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('shipping_city', 'City')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('shipping_state', 'State')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField('shipping_pincode', 'Pincode'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        const Color(0xFF267873), // button ka background
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            color: Colors.white, // text white ho jayega
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
