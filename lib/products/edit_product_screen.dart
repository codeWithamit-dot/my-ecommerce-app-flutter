// lib/products/edit_product_screen.dart

import 'package:flutter/material.dart';
// ✅ FIX: Unnecessary import 'package:flutter/services.dart' hata diya gaya hai.
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
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _categoryController;
  
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _descriptionController = TextEditingController(text: widget.product['description']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _stockQuantityController = TextEditingController(text: widget.product['stock_quantity']?.toString() ?? '0');
    _categoryController = TextEditingController(text: widget.product['category'] ?? '');

    final imageUrlsData = widget.product['image_urls'] as List?;
    _imageUrls = imageUrlsData?.map((e) => e.toString()).toList() ?? [];
  }

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
        'category': _categoryController.text.trim(),
        'is_approved': false,
      }).eq('id', widget.product['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product updated and sent for review!'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop(true);
      
    } on PostgrestException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      appBar: AppBar(
        title: const Text('Edit Product'),
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
                  if (_imageUrls.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _imageUrls[index],
                                width: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  _buildTextField(_nameController, 'Product Name'),
                  _buildTextField(_descriptionController, 'Product Description', maxLines: 4),
                  Row(children: [
                    Expanded(child: _buildTextField(_priceController, 'Price (₹)', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_stockQuantityController, 'Stock Quantity', keyboardType: TextInputType.number)),
                  ]),
                  _buildTextField(_categoryController, 'Category'),
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF267873), width: 2))),
        validator: (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      ),
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