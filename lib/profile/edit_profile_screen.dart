// lib/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late final Map<String, TextEditingController> _controllers;
  late final AppMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = context.read<AppModeProvider>().mode;
    _controllers = _initializeControllers();
    _loadInitialData();
  }
  
  Map<String, TextEditingController> _initializeControllers() {
    // Basic controllers dono ke liye same hain
    final commonControllers = {'full_name': TextEditingController(), 'contact_number': TextEditingController()};

    if (_currentMode == AppMode.buying) {
      return {
        ...commonControllers,
        // BUYER ke liye 'shipping_' wale columns
        'shipping_address_line1': TextEditingController(),
        'shipping_address_line2': TextEditingController(),
        'shipping_city': TextEditingController(),
        'shipping_state': TextEditingController(),
        'shipping_pincode': TextEditingController(),
      };
    } else { // SELLER
      return {
        ...commonControllers,
        // SELLER ke liye 'business_' wale columns
        'business_name': TextEditingController(),
        'about_business': TextEditingController(),
        'business_address_line1': TextEditingController(),
        'business_address_line2': TextEditingController(),
        'business_city': TextEditingController(),
        'business_state': TextEditingController(),
        'business_pincode': TextEditingController(),
        'gstin': TextEditingController(),
        'pan_number': TextEditingController(),
        'bank_account_holder_name': TextEditingController(),
        'bank_account_number': TextEditingController(),
        'bank_ifsc_code': TextEditingController(),
      };
    }
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      if (!mounted) return;
      
      for (final entry in data.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]!.text = entry.value?.toString() ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching profile: ${e.toString()}")));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final updates = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        updates[entry.key] = entry.value.text.trim();
      }
      
      await supabase.from('profiles').update(updates).eq('id', supabase.auth.currentUser!.id);
      
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
      navigator.pop(true);

    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        title: Text(_currentMode == AppMode.buying ? 'Edit Buyer Profile' : 'Edit Seller Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        _currentMode == AppMode.buying
                            ? _buildBuyerForm()
                            : _buildSellerForm(),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF267873),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          labelText: label,
          hintText: isOptional ? 'Optional' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF267873), width: 2),
          ),
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
  
  Widget _buildBuyerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Information'),
        _buildTextField('full_name', 'Your Full Name'),
        _buildTextField('contact_number', 'Your Contact Number'),
        _buildSectionHeader('Default Shipping Address'),
        _buildTextField('shipping_address_line1', 'House No, Building, Street'),
        _buildTextField('shipping_address_line2', 'Area, Landmark', isOptional: true),
        Row(children: [
          Expanded(child: _buildTextField('shipping_city', 'City')),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('shipping_state', 'State')),
        ]),
        _buildTextField('shipping_pincode', 'Pincode'),
      ],
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
        _buildTextField('business_address_line1', 'Address Line 1'),
        _buildTextField('business_address_line2', 'Address Line 2', isOptional: true),
        Row(children: [
          Expanded(child: _buildTextField('business_city', 'City')),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('state', 'State')),
        ]),
        _buildTextField('business_pincode', 'Pincode'),
        _buildSectionHeader('Tax & Bank Details'),
        _buildTextField('gstin', 'GSTIN', isOptional: true),
        _buildTextField('pan_number', 'PAN Card Number'),
        _buildTextField('bank_account_holder_name', 'Account Holder Name'),
        _buildTextField('bank_account_number', 'Bank Account Number'),
        _buildTextField('bank_ifsc_code', 'Bank IFSC Code'),
      ],
    );
  }
}