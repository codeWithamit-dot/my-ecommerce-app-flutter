// lib/products/add_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  
  // --- No changes to logic or functions ---
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submitProduct() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _imageFile == null) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a product image.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';
      await supabase.storage.from('product_images').upload(
        filePath, _imageFile!, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
      final imageUrl = supabase.storage.from('product_images').getPublicUrl(filePath);

      await supabase.from('products').insert({
        'seller_id': userId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'image_url': imageUrl,
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
       _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
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
        title: const Text('Add New Product'),
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
                  _buildImagePicker(),
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
  
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity))
            : const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                    SizedBox(height: 8), Text('Tap to add product image', style: TextStyle(color: Colors.grey)),
                ]),
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
     return ElevatedButton(
      onPressed: _isLoading ? null : _submitProduct,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
        : const Text('Add Product to Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}