// lib/profile/view_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/manage_products_screen.dart';
import 'package:my_ecommerce_app/profile/edit_profile_screen.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:my_ecommerce_app/screens/support/support_hub_screen.dart';
import 'package:my_ecommerce_app/screens/wishlist_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) {
      context.read<UserRoleProvider>().fetchUserProfile();
    }
  }
  
  Future<void> _logout() async {
    if (mounted) {
      context.read<AppModeProvider>().resetMode();
      context.read<UserRoleProvider>().clearProfile();
    }
    await supabase.auth.signOut();
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
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Your Account?'),
              content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('This is a permanent action...'),
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
    final profileProvider = context.watch<UserRoleProvider>();
    final isSeller = profileProvider.role == 'seller';
    
    if (profileProvider.isLoading) return const Center(child: CircularProgressIndicator());
    if (profileProvider.userProfile == null) return const Center(child: Text('Could not load profile.'));
    
    final profile = profileProvider.userProfile!;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: RefreshIndicator(
        onRefresh: () async => await profileProvider.fetchUserProfile(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _buildProfileHeader(context, profile),
            const SizedBox(height: 24),
            _buildActionsCard(context, isSeller),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> profile) {
    return Column(children: [
      CircleAvatar(
        radius: 50,
        backgroundImage: (profile['profile_picture_url'] != null && profile['profile_picture_url']!.isNotEmpty)
            ? NetworkImage(profile['profile_picture_url']!) : null,
        child: (profile['profile_picture_url'] == null || profile['profile_picture_url']!.isEmpty)
            ? const Icon(Icons.person, size: 50) : null,
      ),
      const SizedBox(height: 16),
      Text(profile['full_name'] ?? 'Anonymous User', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      Text(supabase.auth.currentUser?.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _navigateToEditProfile,
        child: const Text("Edit Profile"),
      ),
    ]);
  }

  Widget _buildActionsCard(BuildContext context, bool isSeller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          children: [
            if (isSeller)
              _buildMenuItem(context, icon: Icons.inventory_2_outlined, title: 'Manage My Products',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageProductsScreen()))),
            
            if (!isSeller)
              _buildMenuItem(context, icon: Icons.favorite_border, title: 'My Wishlist',
                iconColor: Colors.redAccent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistScreen()))),

            _buildMenuItem(context, icon: Icons.support_agent_outlined, title: 'Help & Support',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SupportHubScreen()))),
            
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            _buildMenuItem(context, icon: Icons.logout, title: 'Logout', textColor: Colors.blue[700],
              onTap: _logout),

            const Divider(height: 1, indent: 16, endIndent: 16),

            _buildMenuItem(context, icon: Icons.delete_forever_outlined, title: 'Delete My Account', textColor: Colors.red[700],
              onTap: _showDeleteConfirmationDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, Color? textColor, Color? iconColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}