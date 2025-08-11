// lib/profile/view_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = true;
  
  final Map<String, TextEditingController> _controllers = {};
  
  late final AppMode _currentMode;
  
  @override
  void initState() {
    super.initState();
    _currentMode = context.read<AppModeProvider>().mode;
    _loadProfileData();
  }
  
  Future<void> _loadProfileData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();
      
      if (mounted) {
        // --- BADLAAV 1: forEach ki jagah for...in loop ---
        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          _controllers[key] = TextEditingController(text: value?.toString() ?? '');
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching data: ${e.toString()}")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if(!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final Map<String, dynamic> updatedData = {};
    // --- BADLAAV 2: forEach ki jagah for...in loop ---
    for (final entry in _controllers.entries) {
      updatedData[entry.key] = entry.value.text.trim();
    }

    try {
      await supabase.from('profiles').update(updatedData).eq('id', supabase.auth.currentUser!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.of(context).pop();
      }
    } catch(e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating profile: ${e.toString()}")));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // --- BADLAAV 3: forEach ki jagah for...in loop ---
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Niche ka build method waise ka waisa hi rahega
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentMode == AppMode.buying ? "My Buyer Profile" : "My Seller Profile")),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentMode == AppMode.buying) _buildBuyerForm() else _buildSellerForm(),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => v!.isEmpty && label != 'GSTIN (Optional)' ? '$label is required' : null,
      ),
    );
  }
  
  Widget _buildBuyerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Details'),
        _buildTextField('full_name', 'Full Name'),
        _buildTextField('contact_number', 'Contact Number'),
        const SizedBox(height: 20),
        _buildSectionHeader('Shipping Address'),
        _buildTextField('shipping_address_line1', 'House No, Building Name'),
        _buildTextField('shipping_locality', 'Area, Locality'),
        _buildTextField('shipping_city', 'City'),
        _buildTextField('shipping_state', 'State'),
        _buildTextField('shipping_pincode', 'Pincode'),
      ],
    );
  }
  
  Widget _buildSellerForm() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Business Information'),
        _buildTextField('business_name', 'Business Name'),
        _buildTextField('about_business', 'About Your Business'),
        _buildTextField('contact_number', 'Contact Number'),

        const SizedBox(height: 20),
        _buildSectionHeader('Pickup Address'),
        _buildTextField('business_address_line1', 'Address'),
        _buildTextField('business_locality', 'Locality'),
        _buildTextField('business_city', 'City'),
        _buildTextField('business_state', 'State'),
        _buildTextField('business_pincode', 'Pincode'),

        const SizedBox(height: 20),
        _buildSectionHeader('Tax & Bank Details'),
        // Optional field doesn't need a strict validator
        TextFormField(controller: _controllers['gstin'], decoration: const InputDecoration(labelText: 'GSTIN (Optional)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        _buildTextField('pan_number', 'PAN Number'),
        _buildTextField('bank_account_holder_name', 'Account Holder Name'),
        _buildTextField('bank_account_number', 'Account Number'),
        _buildTextField('bank_ifsc_code', 'IFSC Code'),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}