// lib/screens/search_filters_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';

class SearchFiltersScreen extends StatefulWidget {
  final String? initialCategory;
  final RangeValues? initialPriceRange;

  const SearchFiltersScreen({
    super.key,
    this.initialCategory,
    this.initialPriceRange,
  });

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  String? _selectedCategory;
  RangeValues? _selectedPriceRange;
  late Future<List<String>> _categoriesFuture;
  final double _maxPrice = 50000; 

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedPriceRange = widget.initialPriceRange ?? RangeValues(0, _maxPrice);
    _categoriesFuture = _fetchCategories();
  }

  // Fetches unique category names from your 'products' table
  Future<List<String>> _fetchCategories() async {
    try {
      final response = await supabase
        .from('products')
        .select('category');
      
      // ✅ FIXED: This is the corrected logic to handle nulls and return the correct type.
      final categories = (response as List)
          .map((item) => item['category'] as String?) // Safely get the category as a nullable String
          .whereType<String>()                      // Filter out any null values AND cast the result to a non-nullable Iterable<String>
          .toSet()                                   // Get only the unique category names
          .toList();                                 // Convert it back to a List<String>
      
      return categories;
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  void _applyFilters() {
    final result = {
      'category': _selectedCategory,
      'priceRange': _selectedPriceRange,
    };
    Navigator.of(context).pop(result);
  }
  
  void _clearFilters() {
      setState(() {
        _selectedCategory = null;
        _selectedPriceRange = RangeValues(0, _maxPrice);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(onPressed: _clearFilters, child: const Text('Clear All', style: TextStyle(color: Colors.white)))
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: Theme.of(context).textTheme.titleLarge),
                // Use a check here in case no categories were found
                if (categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No categories available to filter.'),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    children: categories.map((category) => ChoiceChip(
                      label: Text(category),
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(color: _selectedCategory == category ? Colors.white : Colors.black),
                      selected: _selectedCategory == category,
                      onSelected: (isSelected) {
                        setState(() {
                          _selectedCategory = isSelected ? category : null;
                        });
                      },
                    )).toList(),
                  ),

                const Divider(height: 40),
                
                Text('Price Range', style: Theme.of(context).textTheme.titleLarge),
                RangeSlider(
                  values: _selectedPriceRange!,
                  min: 0,
                  max: _maxPrice,
                  divisions: 50,
                  labels: RangeLabels(
                    '₹${_selectedPriceRange!.start.round()}',
                    '₹${_selectedPriceRange!.end.round()}',
                  ),
                  onChanged: (values) {
                    setState(() => _selectedPriceRange = values);
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}