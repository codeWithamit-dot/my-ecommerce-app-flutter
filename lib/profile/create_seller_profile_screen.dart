// lib/profile/create_seller_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/home_screen.dart'; 
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/utils/indian_states.dart';

class CreateSellerProfileScreen extends StatefulWidget {
  const CreateSellerProfileScreen({super.key});

  @override
  State<CreateSellerProfileScreen> createState() => _CreateSellerProfileScreenState();
}

class _CreateSellerProfileScreenState extends State<CreateSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers waise ke waise hi rahenge
  final _businessNameCtrl = TextEditingController();
  String? _businessType;
  final _aboutCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String? _selectedState;
  final _bankAccountHolderCtrl = TextEditingController();
  final _bankAccountNumberCtrl = TextEditingController();
  final _bankIfscCtrl = TextEditingController();

  var _isLoading = false;
  final _businessTypes = ['Sole Proprietorship', 'Partnership', 'Private Limited Company', 'Other'];
  
  Future<void> _saveProfile() async {
     if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({
        'business_name': _businessNameCtrl.text.trim(),
        'business_type': _businessType,
        'about_business': _aboutCtrl.text.trim(),
        'contact_number': _phoneCtrl.text.trim(),
        'business_address_line1': _addressLine1Ctrl.text.trim(),
        'business_locality': _localityCtrl.text.trim(),
        'business_city': _cityCtrl.text.trim(),
        'business_state': _selectedState,
        'business_pincode': _pincodeCtrl.text.trim(),
        'gstin': _gstinCtrl.text.trim().toUpperCase(),
        'pan_number': _panCtrl.text.trim().toUpperCase(),
        'bank_account_holder_name': _bankAccountHolderCtrl.text.trim(),
        'bank_account_number': _bankAccountNumberCtrl.text.trim(),
        'bank_ifsc_code': _bankIfscCtrl.text.trim(),
        'is_seller_profile_complete': true,
        'seller_status': 'pending_approval', 
      }).eq('id', user.id);

       if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
       }
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Seller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text('Seller Registration', style: Theme.of(context).textTheme.headlineSmall),
               const Text('Please provide your details to get verified.'),
               const SizedBox(height: 20),
              
              _buildSectionHeader('Business Information'),
              TextFormField(controller: _businessNameCtrl, decoration: const InputDecoration(labelText: 'Business Name / Shop Name'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField(value: _businessType, items: _businessTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v)=>_businessType = v, hint: const Text('Type of Business'), validator: (v)=> v==null ? 'Required':null),
              const SizedBox(height: 12),
              TextFormField(controller: _aboutCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'About Your Business'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Business Contact Number'), validator: (v)=>v!.isEmpty ? 'Required' : null),

              const SizedBox(height: 20),
              _buildSectionHeader('Pickup Address'),
              TextFormField(controller: _addressLine1Ctrl, decoration: const InputDecoration(labelText: 'Address (Building, Street, etc.)'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _localityCtrl, decoration: const InputDecoration(labelText: 'Area / Locality'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              // --- YAHAN BADLAAV KIYA GAYA HAI ---
              // Ab hum Row ki jagah in dono ko ek ke neeche ek rakh rahe hain
              DropdownButtonFormField<String>(
                value: _selectedState,
                items: indianStates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                hint: const Text('State'),
                validator: (v) => v == null ? 'Required' : null
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincodeCtrl,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null
              ),
              // --- BADLAAV KHATAM ---
               
              const SizedBox(height: 20),
              _buildSectionHeader('Tax & Bank Details'),
               TextFormField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)')),
               const SizedBox(height: 12),
               TextFormField(controller: _panCtrl, decoration: const InputDecoration(labelText: 'PAN Number (Business or Personal)'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
               TextFormField(controller: _bankAccountHolderCtrl, decoration: const InputDecoration(labelText: 'Bank Account Holder Name'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _bankAccountNumberCtrl, decoration: const InputDecoration(labelText: 'Bank Account Number'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _bankIfscCtrl, decoration: const InputDecoration(labelText: 'Bank IFSC Code'), validator: (v)=>v!.isEmpty ? 'Required' : null),
              
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _isLoading ? null : _saveProfile, child: _isLoading ? const CircularProgressIndicator() : const Text('Submit for Verification')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
        ],
      ),
    );
  }
}