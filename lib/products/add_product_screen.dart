// lib/products/add_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:path/path.dart' as p; // Filename nikalne ke liye

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    try {
      final pickedFiles = await picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles;
        });
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select at least one product image.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> imageUrls = [];
      final sellerId = supabase.auth.currentUser!.id;

      for (final image in _selectedImages) {
        final imageFile = File(image.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
        
        await supabase.storage.from('product_images').upload(fileName, imageFile);

        final imageUrl = supabase.storage.from('product_images').getPublicUrl(fileName);
        imageUrls.add(imageUrl);
      }
      
      final productData = {
        'seller_id': sellerId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _categoryController.text.trim(),
        'stock_quantity': int.parse(_stockQuantityController.text.trim()),
        'image_urls': imageUrls,
        'is_approved': false,
      };

      await supabase.from('products').insert(productData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product added and sent for review!'),
        backgroundColor: Colors.green,
      ));
      
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add product: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: const Color(0xFF267873),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F7F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Product Name'),
              _buildTextField(_descriptionController, 'Product Description', maxLines: 4),
              Row(children: [
                Expanded(child: _buildTextField(_priceController, 'Price (₹)', keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_stockQuantityController, 'Stock Quantity', keyboardType: TextInputType.number)),
              ]),
              _buildTextField(_categoryController, 'Category (e.g., Fashion, Home Decor)'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Add Product & Submit for Review'),
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF267873),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF267873), width: 2))),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label is required.';
          if (keyboardType == TextInputType.number && double.tryParse(value) == null) return 'Please enter a valid number.';
          return null;
        },
      ),
    );
  }
  
  Widget _buildImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Product Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
      const SizedBox(height: 8),
      Container(
        height: 120,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        child: _selectedImages.isEmpty
            ? Center(child: TextButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Select Images'),
                onPressed: _pickImages))
            : GridView.builder(
                padding: const EdgeInsets.all(8), scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 8),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(children: [
                      Image.file(File(_selectedImages[index].path), fit: BoxFit.cover, width: 100, height: 100),
                      Positioned(right: -10, top: -10, child: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setState(() => _selectedImages.removeAt(index))))
                  ]);
                },
              ),
      ),
      if (_selectedImages.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _pickImages, child: const Text('Change/Add More')),
          ),
        ),
    ]);
  }
}