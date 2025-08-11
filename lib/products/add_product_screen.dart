// lib/products/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_ecommerce_app/main.dart'; // For supabase client

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedCategory;

  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  var _isLoading = false;

  final List<String> _categories = ["Electronics", "Fashion", "Home & Kitchen", "Books", "Sports", "Grocery"];

  // Function to pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  // Main function to save the product
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one image.')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final List<String> imageUrls = [];

      // Step 1: Upload images to Supabase Storage
      for (final image in _images) {
        final file = File(image.path);
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}';
        
        await supabase.storage.from('product_images').upload(fileName, file);
        final imageUrl = supabase.storage.from('product_images').getPublicUrl(fileName);
        imageUrls.add(imageUrl);
      }
      
      // Step 2: Insert product data into 'products' table
      await supabase.from('products').insert({
        'seller_id': userId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'stock_quantity': int.parse(_stockController.text.trim()),
        'image_urls': imageUrls, // Save the list of URLs
        'is_approved': false, // Default to not approved for admin review
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product submitted for review!')));
        Navigator.of(context).pop(); // Go back to the seller dashboard
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: Column(
                  children: [
                    _images.isEmpty
                      ? const Text('No images selected.')
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _images.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                          itemBuilder: (context, index) => Image.file(File(_images[index].path), fit: BoxFit.cover),
                        ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Images'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Product Description'), maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select Category'),
                onChanged: (value) => setState(() => _selectedCategory = value),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save & Submit for Review'),
              )
            ],
          ),
        ),
      ),
    );
  }
}