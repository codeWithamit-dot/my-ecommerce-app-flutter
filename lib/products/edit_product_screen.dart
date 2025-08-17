// lib/products/edit_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_ecommerce_app/main.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockQuantityController;
  late String _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _descriptionController = TextEditingController(text: widget.product['description']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _stockQuantityController = TextEditingController(text: widget.product['stock_quantity']?.toString() ?? '0');
    _imageUrl = widget.product['image_url'];
  }

  // --- No changes to logic or functions ---
  Future<void> _updateProduct() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    setState(() => _isLoading = true);
    try {
      await supabase.from('products').update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
      }).eq('id', widget.product['id']); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _descriptionController.dispose(); _priceController.dispose(); _stockQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ UI UPDATE: Themed AppBar and background color
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Card( // ✅ UI UPDATE: Form is now inside a Card
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_imageUrl.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_imageUrl, height: 180, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey,))),
                  const SizedBox(height: 24),
                  _buildTextField(_nameController, 'Product Name', validator: (v) => v!.isEmpty ? 'Name required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'Product Description', maxLines: 4),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildTextField(_priceController, 'Price (₹)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) => v!.isEmpty ? 'Price required' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_stockQuantityController, 'Stock Quantity', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Stock required' : null)),
                  ]),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ UI HELPER WIDGETS
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF267873), width: 2))),
      maxLines: maxLines, keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateProduct,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}