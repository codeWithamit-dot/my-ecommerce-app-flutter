// lib/profile/create_buyer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/home_screen.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/utils/indian_states.dart'; 

class CreateBuyerProfileScreen extends StatefulWidget {
  const CreateBuyerProfileScreen({super.key});

  @override
  State<CreateBuyerProfileScreen> createState() => _CreateBuyerProfileScreenState();
}

class _CreateBuyerProfileScreenState extends State<CreateBuyerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _localityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String? _selectedState;
  var _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // --- LOGIC MEIN BADLAAV YAHAN HAI ---
      await supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'contact_number': _phoneController.text.trim(),
        'shipping_address_line1': _addressLine1Controller.text.trim(),
        'shipping_locality': _localityController.text.trim(),
        'shipping_landmark': _landmarkController.text.trim(),
        'shipping_city': _cityController.text.trim(),
        'shipping_state': _selectedState,
        'shipping_pincode': _pincodeController.text.trim(),
        // BADLAAV 1: Hum ab specific buyer profile flag ko update kar rahe hain
        'is_buyer_profile_complete': true,
      }).eq('id', user.id);

      if (mounted) {
        // Form save hone ke baad user ko vapas home screen par bhej do
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // UI mein koi badlaav nahi hai
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Your Buyer Account', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Text("Personal Details", style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              Text("Default Shipping Address", style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              TextFormField(controller: _addressLine1Controller, decoration: const InputDecoration(labelText: 'House No., Building Name, Street'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _localityController, decoration: const InputDecoration(labelText: 'Area, Locality'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark (e.g. Near City Hospital)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _pincodeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pincode'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                hint: const Text('Select State'),
                onChanged: (val) => setState(() => _selectedState = val),
                items: indianStates.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
                validator: (v) => v == null ? 'Please select a state' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save & Start Shopping'),
              )
            ],
          ),
        ),
      ),
    );
  }
}