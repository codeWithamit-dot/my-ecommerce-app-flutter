// lib/profile/create_buyer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';
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
    'contact_number': TextEditingController(),
    'shipping_address_line1': TextEditingController(),
    'shipping_address_line2': TextEditingController(),
    'shipping_city': TextEditingController(),
    'shipping_state': TextEditingController(),
    'shipping_pincode': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields with existing data from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserRoleProvider>().userProfile;
      if (profile != null) {
        _controllers['full_name']?.text = profile['full_name'] ?? '';
        _controllers['contact_number']?.text = profile['contact_number'] ?? '';
        _controllers['shipping_address_line1']?.text = profile['shipping_address_line1'] ?? '';
        _controllers['shipping_address_line2']?.text = profile['shipping_address_line2'] ?? '';
        _controllers['shipping_city']?.text = profile['shipping_city'] ?? '';
        _controllers['shipping_state']?.text = profile['shipping_state'] ?? '';
        _controllers['shipping_pincode']?.text = profile['shipping_pincode'] ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updates = {
        'is_buyer_profile_complete': true,
        'full_name': _controllers['full_name']!.text.trim(),
        'contact_number': _controllers['contact_number']!.text.trim(),
        'shipping_address_line1': _controllers['shipping_address_line1']!.text.trim(),
        'shipping_address_line2': _controllers['shipping_address_line2']!.text.trim(),
        'shipping_city': _controllers['shipping_city']!.text.trim(),
        'shipping_state': _controllers['shipping_state']!.text.trim(),
        'shipping_pincode': _controllers['shipping_pincode']!.text.trim(),
      };
      
      // Async operation
      await supabase.from('profiles').update(updates).eq('id', supabase.auth.currentUser!.id);

      // ⭐️ FIX: Check if the widget is still mounted BEFORE using context.
      if (!mounted) return;

      // Now, safely use context to get providers and navigators.
      final userProfileProvider = context.read<UserRoleProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      await userProfileProvider.fetchUserProfile();
      
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Profile saved successfully!'),
        backgroundColor: Colors.green,
      ));
      
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);

    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Profile'), backgroundColor: const Color(0xFF267873), foregroundColor: Colors.white),
      backgroundColor: const Color(0xFFE0F7F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Card(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildSectionHeader('Personal Information'),
                  _buildTextField('full_name', 'Your Full Name'),
                  const SizedBox(height: 16),
                  _buildTextField('contact_number', 'Your Contact Number'),
                  _buildSectionHeader('Default Shipping Address'),
                  _buildTextField('shipping_address_line1', 'House No, Building, Street'),
                  const SizedBox(height: 16),
                  _buildTextField('shipping_address_line2', 'Area, Landmark', isOptional: true),
                  const SizedBox(height: 16),
                  Row(children: [
                      Expanded(child: _buildTextField('shipping_city', 'City')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('shipping_state', 'State')),
                  ]),
                  const SizedBox(height: 16),
                  _buildTextField('shipping_pincode', 'Pincode'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF267873), foregroundColor: Colors.white,),
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildTextField(String key, String label, {bool isOptional = false}) {
    return TextFormField(controller: _controllers[key],
      decoration: InputDecoration(labelText: label, hintText: isOptional ? 'Optional' : '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF267873), width: 2)),
      ),
      validator: (v) {
        if (!isOptional && v!.trim().isEmpty) return '$label is required';
        return null;
      },
    );
  }
}