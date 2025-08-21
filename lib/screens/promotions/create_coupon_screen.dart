// Path: lib/screens/promotions/create_coupon_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/services/coupon_service.dart';

class CreateCouponScreen extends StatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _couponService = CouponService();

  // Form Controllers
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  
  String _discountType = 'percentage'; // Default value
  DateTime? _validUntil;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _couponService.createSellerCoupon(
          code: _codeController.text,
          discountType: _discountType,
          discountValue: double.parse(_valueController.text),
          minPurchaseAmount: double.tryParse(_minPurchaseController.text) ?? 0.0,
          validUntil: _validUntil,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created successfully!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minPurchaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Coupon'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Coupon Code (e.g., SAVE10)'),
              textCapitalization: TextCapitalization.characters,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a coupon code' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _discountType,
              items: const [
                DropdownMenuItem(value: 'percentage', child: Text('Percentage Discount')),
                DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount Discount')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _discountType = value);
              },
              decoration: const InputDecoration(labelText: 'Discount Type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Discount Value', 
                prefixText: _discountType == 'percentage' ? null : '₹',
                suffixText: _discountType == 'percentage' ? '%' : null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a value';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minPurchaseController,
              decoration: const InputDecoration(
                labelText: 'Minimum Purchase Amount (Optional)',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date (Optional)'),
              subtitle: Text(_validUntil == null ? 'No expiry' : DateFormat('d MMM, yyyy').format(_validUntil!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('Create Coupon'),
        ),
      ),
    );
  }
}