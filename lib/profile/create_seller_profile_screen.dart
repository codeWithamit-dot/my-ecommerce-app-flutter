// lib/profile/create_seller_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateSellerProfileScreen extends StatefulWidget {
  const CreateSellerProfileScreen({super.key});
  @override
  State<CreateSellerProfileScreen> createState() =>
      _CreateSellerProfileScreenState();
}

class _CreateSellerProfileScreenState extends State<CreateSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _controllers = {
    'full_name': TextEditingController(),
    'contact_number': TextEditingController(),
    'business_name': TextEditingController(),
    'about_business': TextEditingController(),
    'business_address_line1': TextEditingController(),
    'business_locality': TextEditingController(),
    'business_landmark': TextEditingController(),
    'business_city': TextEditingController(),
    'business_state': TextEditingController(),
    'business_pincode': TextEditingController(),
    'gstin': TextEditingController(),
    'pan_number': TextEditingController(),
    'bank_account_holder_name': TextEditingController(),
    'bank_account_number': TextEditingController(),
    'bank_ifsc_code': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserRoleProvider>().userProfile;
      if (profile != null) {
        _controllers['full_name']?.text = profile['full_name'] ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final updates = <String, dynamic>{
        'is_seller_profile_complete': true,
        'seller_status': 'pending', // Yahan hum status ko 'pending' bhej rahe hain
      };
      
      for (final entry in _controllers.entries) {
        updates[entry.key] = entry.value.text.trim();
      }
      
      await supabase.from('profiles').update(updates).eq('id', supabase.auth.currentUser!.id);
      
      if (!mounted) return;

      final userProfileProvider = context.read<UserRoleProvider>();
      final appModeProvider = context.read<AppModeProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // ✅ FIX: `fetchUserProfile()` se network call karne ke bajaye,
      // Provider ko locally update kar do. Yeh zyada fast hai.
      userProfileProvider.updateLocalProfile(updates);
      
      appModeProvider.switchTo(AppMode.selling);
      
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Seller profile submitted for review!'),
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
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('Setup Your Seller Profile'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSellerForm(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF267873),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save & Submit for Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField(String key, String label, {bool isOptional = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[key],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, hintText: isOptional ? 'Optional' : '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF267873), width: 2)),
        ),
        validator: (v) {
          if (!isOptional && v!.trim().isEmpty) return '$label is required';
          return null;
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),
    );
  }
  
  Widget _buildSellerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Basic Information'),
        _buildTextField('full_name', 'Your Full Name'),
        _buildTextField('contact_number', 'Your Contact Number'),
        _buildSectionHeader('Business Details'),
        _buildTextField('business_name', 'Store / Business Name'),
        _buildTextField('about_business', 'About Your Business', maxLines: 3),
        _buildSectionHeader('Pickup Address'),
        _buildTextField('business_address_line1', 'Address (Building, Street, etc.)'),
        _buildTextField('business_locality', 'Locality / Area'),
        _buildTextField('business_landmark', 'Landmark (Optional)', isOptional: true),
        Row(children: [
          Expanded(child: _buildTextField('business_city', 'City')),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('business_state', 'State')),
        ]),
        _buildTextField('business_pincode', 'Pincode'),
        _buildSectionHeader('Tax & Bank Details'),
        _buildTextField('gstin', 'GSTIN (Optional)', isOptional: true),
        _buildTextField('pan_number', 'PAN Card Number'),
        _buildTextField('bank_account_holder_name', 'Account Holder Name'),
        _buildTextField('bank_account_number', 'Bank Account Number'),
        _buildTextField('bank_ifsc_code', 'Bank IFSC Code'),
      ],
    );
  }
}