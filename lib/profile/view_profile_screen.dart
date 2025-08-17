// lib/profile/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/manage_products_screen.dart';
import 'package:my_ecommerce_app/profile/edit_profile_screen.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/screens/support/support_hub_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  Future<Map<String, dynamic>> _fetchProfile() {
    final userId = supabase.auth.currentUser!.id;
    return supabase.from('profiles').select().eq('id', userId).single();
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String title, required String? value}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        (value == null || value.isEmpty) ? 'Not Provided' : value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))
        .then((wasProfileUpdated) {
      if (wasProfileUpdated == true) setState(() {});
    });
  }
  
  Future<void> _logout() async {
    await supabase.auth.signOut();
  }

  Future<void> _deleteAccount() async {
    // Hide the confirmation dialog
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    try {
      await supabase.functions.invoke('delete-user');
    } 
    on FunctionException catch (error) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ✅ FIX: `error.message` ki jagah `error.toString()` istemal karein
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    bool isCheckboxChecked = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Your Account?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'This is a permanent action. All your data, including profile, products, and order history, will be deleted forever.'),
                    const SizedBox(height: 16),
                    Text(
                      'This cannot be undone.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isCheckboxChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              isCheckboxChecked = value ?? false;
                            });
                          },
                        ),
                        const Flexible(child: Text("I understand and wish to proceed.")),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Go Back'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckboxChecked ? Colors.red : Colors.grey,
                  ),
                  onPressed: isCheckboxChecked ? _deleteAccount : null,
                  child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSellerMode = context.watch<AppModeProvider>().mode == AppMode.selling;
    final userEmail = supabase.auth.currentUser?.email ?? 'No email';

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error ?? "Could not load profile."}'));
        }

        final profile = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              _buildBasicInfoCard(context, profile, userEmail, isSellerMode),
              _buildActionsCard(context, isSellerMode),
              if (isSellerMode)
                _buildSellerDetails(context, profile)
              else
                _buildBuyerDetails(context, profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, Map<String, dynamic> profile, String userEmail, bool isSellerMode) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            Text(profile['full_name'] ?? 'N/A', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(userEmail, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
            if (isSellerMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Chip(avatar: const Icon(Icons.store), label: Text(profile['store_name'] ?? 'N/A')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, bool isSellerMode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          if (isSellerMode)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Manage My Products'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
              ),
            ),
          
          if (isSellerMode) const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToEditProfile,
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SupportHubScreen()),
              );
            },
          ),
          
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          ListTile(
            leading: Icon(Icons.logout, color: Colors.blue[700]),
            title: Text('Logout', style: TextStyle(color: Colors.blue[700])),
            onTap: _logout,
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red[700]),
            title: Text('Delete My Account', style: TextStyle(color: Colors.red[700])),
            onTap: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBuyerDetails(BuildContext context, Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contact & Shipping Details'),
        _buildDetailRow(context, icon: Icons.phone_outlined, title: 'Contact Number', value: profile['phone']),
        _buildDetailRow(context, icon: Icons.home_work_outlined, title: 'Address', value: profile['address']),
      ],
    );
  }

  Widget _buildSellerDetails(BuildContext context, Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Business Information'),
        _buildDetailRow(context, icon: Icons.storefront, title: 'Store Name', value: profile['store_name']),
        _buildDetailRow(context, icon: Icons.info_outline, title: 'About Business', value: profile['about_business']),
        _buildDetailRow(context, icon: Icons.phone_in_talk_outlined, title: 'Business Contact', value: profile['phone']),

        _buildSectionHeader('Pickup Address'),
        _buildDetailRow(context, icon: Icons.warehouse_outlined, title: 'Address', value: profile['pickup_address_line1']),
        _buildDetailRow(context, icon: Icons.location_city, title: 'City', value: profile['pickup_city']),

        _buildSectionHeader('Tax & Bank Details'),
        _buildDetailRow(context, icon: Icons.receipt_long_outlined, title: 'GSTIN', value: profile['gstin']),
        _buildDetailRow(context, icon: Icons.credit_card_outlined, title: 'PAN Number', value: profile['pan_number']),
        _buildDetailRow(context, icon: Icons.account_balance, title: 'Bank A/C', value: profile['bank_account_number']),
      ],
    );
  }
}