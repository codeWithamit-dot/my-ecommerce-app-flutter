// lib/profile/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/manage_products_screen.dart';
import 'package:my_ecommerce_app/profile/edit_profile_screen.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:my_ecommerce_app/screens/support/support_hub_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {

  Future<void> _navigateToEditProfile() async {
    // Navigator push aage jaakar context istemal karta hai.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    
    if (result == true && mounted) {
      // Wapas aane ke baad profile refresh karo.
      context.read<UserRoleProvider>().fetchUserProfile();
    }
  }
  
  Future<void> _logout() async {
    // Pehle `await` wala kaam poora hone do.
    await supabase.auth.signOut();
    
    // Ab `mounted` check karke hi context istemal karo.
    if (!mounted) return;
    context.read<UserRoleProvider>().clearProfile();
    context.read<AppModeProvider>().resetMode();
  }

  Future<void> _deleteAccount() async {
    final currentContext = context;
    try {
      await supabase.functions.invoke('delete-user');
      
      if (!currentContext.mounted) return;
      currentContext.read<UserRoleProvider>().clearProfile();
      currentContext.read<AppModeProvider>().resetMode();
    } on FunctionException catch (error) { 
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(SnackBar(
        content: Text('Error: ${error.details ?? 'Could not delete account.'}'),
        backgroundColor: Theme.of(currentContext).colorScheme.error,
      ));
    }
  }

  void _showDeleteConfirmationDialog() {
    bool isCheckboxChecked = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // Alag context ka naam de do
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Your Account?'),
              content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('This action is permanent. All your data...will be deleted forever.'),
                    const SizedBox(height: 16),
                    Text('This cannot be undone.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                    const SizedBox(height: 16),
                    Row(children: [ Checkbox(value: isCheckboxChecked, onChanged: (bool? value) => setState(() => isCheckboxChecked = value ?? false)),
                        const Flexible(child: Text("I understand and wish to proceed.")), ],),
                  ],)),
              actions: <Widget>[
                TextButton(child: const Text('Go Back'), onPressed: () => Navigator.of(dialogContext).pop()),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isCheckboxChecked ? Colors.red : Colors.grey),
                  onPressed: () {
                    if (isCheckboxChecked) {
                      Navigator.of(dialogContext).pop();
                      _deleteAccount();
                    }
                  },
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
    // ✅ FIX: 'appProvider' ab use ho raha hai 'isSellerMode' set karne ke liye.
    final appProvider = context.watch<AppModeProvider>();
    final profileProvider = context.watch<UserRoleProvider>();
    
    if (profileProvider.isLoading) return const Center(child: CircularProgressIndicator());
    if (profileProvider.userProfile == null) return const Center(child: Text('Could not load profile.'));
    
    final profile = profileProvider.userProfile!;
    final isSellerRole = profileProvider.role == 'seller';
    final isSellerMode = appProvider.mode == AppMode.selling; // Ise use karenge

    return RefreshIndicator(
      onRefresh: () async => await profileProvider.fetchUserProfile(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _buildBasicInfoCard(context, profile, isSellerMode),
          _buildActionsCard(context, isSellerRole), // Pass isSellerRole here
          if (isSellerRole)
            _buildSellerDetails(context, profile)
          else
            _buildBuyerDetails(context, profile),
        ],
      ),
    );
  }
  
  // --- WIDGET BUILDERS (koi change nahi) ---
  
  Widget _buildBasicInfoCard(BuildContext context, Map<String, dynamic> profile, bool isSellerMode) {
    return Card(elevation: 4, margin: const EdgeInsets.all(10), child: Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
      CircleAvatar(radius: 40,
        backgroundImage: (profile['profile_picture_url'] != null && profile['profile_picture_url']!.isNotEmpty) ? NetworkImage(profile['profile_picture_url']!) : null,
        child: (profile['profile_picture_url'] == null || profile['profile_picture_url']!.isEmpty) ? const Icon(Icons.person, size: 40) : null),
      const SizedBox(height: 12),
      Text(profile['full_name'] ?? 'N/A', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(supabase.auth.currentUser?.email ?? 'No email', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
      if (isSellerMode)
        Padding(padding: const EdgeInsets.only(top: 8.0),
          child: Chip(avatar: const Icon(Icons.store), label: Text(profile['business_name'] ?? 'N/A')))])));
  }

  Widget _buildActionsCard(BuildContext context, bool isSeller) {
    return Card(margin: const EdgeInsets.symmetric(horizontal: 10), child: Column(children: [
      if (isSeller) ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Manage My Products'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageProductsScreen()))),
      if (isSeller) const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit Profile'), trailing: const Icon(Icons.chevron_right), onTap: _navigateToEditProfile),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: const Icon(Icons.support_agent_outlined), title: const Text('Help & Support'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SupportHubScreen()))),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: Icon(Icons.logout, color: Colors.blue[700]), title: Text('Logout', style: TextStyle(color: Colors.blue[700])), onTap: _logout),
      const Divider(height: 1, indent: 16, endIndent: 16),
      ListTile(leading: Icon(Icons.delete_forever_outlined, color: Colors.red[700]), title: Text('Delete My Account', style: TextStyle(color: Colors.red[700])), onTap: _showDeleteConfirmationDialog),
    ]));
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String title, required String? value}) {
    return ListTile(leading: Icon(icon, color: Colors.grey[600], size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text((value == null || value.isEmpty) ? 'Not Provided' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)));
  }

  Widget _buildBuyerDetails(BuildContext context, Map<String, dynamic> profile) {
    final address = "${profile['shipping_address_line1'] ?? ''} ${profile['shipping_address_line2'] ?? ''}".trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Contact & Shipping Details'),
      _buildDetailRow(context, icon: Icons.phone_outlined, title: 'Contact Number', value: profile['contact_number']),
      _buildDetailRow(context, icon: Icons.home_work_outlined, title: 'Shipping Address', value: address.isEmpty ? 'Not Provided' : address),
    ]);
  }

  Widget _buildSellerDetails(BuildContext context, Map<String, dynamic> profile) {
    final pickupAddress = "${profile['business_address_line1'] ?? ''}, ${profile['business_locality'] ?? ''}".trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Business Information'),
      _buildDetailRow(context, icon: Icons.storefront, title: 'Store Name', value: profile['business_name']),
      _buildDetailRow(context, icon: Icons.info_outline, title: 'About Business', value: profile['about_business']),
      _buildDetailRow(context, icon: Icons.phone_in_talk_outlined, title: 'Business Contact', value: profile['contact_number']),
      _buildSectionHeader('Pickup Address'),
      _buildDetailRow(context, icon: Icons.warehouse_outlined, title: 'Address', value: pickupAddress),
      _buildDetailRow(context, icon: Icons.location_city, title: 'City', value: profile['business_city']),
      _buildSectionHeader('Tax & Bank Details'),
      _buildDetailRow(context, icon: Icons.receipt_long_outlined, title: 'GSTIN', value: profile['gstin']),
      _buildDetailRow(context, icon: Icons.credit_card_outlined, title: 'PAN Number', value: profile['pan_number']),
      _buildDetailRow(context, icon: Icons.account_balance, title: 'Bank A/C', value: profile['bank_account_number']),
    ]);
  }
}