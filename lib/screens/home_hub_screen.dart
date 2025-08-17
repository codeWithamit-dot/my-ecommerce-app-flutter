// lib/screens/home_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ecommerce_app/products/add_product_screen.dart';
import 'package:my_ecommerce_app/profile/view_profile_screen.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart'; // ✅ FIX: Wapas purana naam
import 'package:my_ecommerce_app/screens/cart_manager_screen.dart';
import 'package:my_ecommerce_app/screens/orders_manager_screen.dart';
import 'package:my_ecommerce_app/screens/categories_screen.dart';
import 'package:my_ecommerce_app/screens/home_page_content.dart';
import 'package:my_ecommerce_app/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({super.key});
  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _pages = <Widget>[ HomePageContent(), CategoriesScreen(), CartManagerScreen(), OrdersManagerScreen(), ViewProfileScreen() ];
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  void _logout() async => await Supabase.instance.client.auth.signOut();
  void _navigateToAddProduct() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()));
  void _navigateToSearch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppModeProvider, UserRoleProvider>( // ✅ FIX: Wapas purana naam
      builder: (context, appModeProvider, profileProvider, child) {
        
        if (profileProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isBuyingMode = appModeProvider.mode == AppMode.buying;
        final approvalStatus = profileProvider.approvalStatus;

        if (!isBuyingMode && approvalStatus == 'pending') {
          return const SellerPendingApprovalScreen();
        }
        
        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: _pages),
          appBar: _buildAppBar(isBuyingMode, appModeProvider),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }
  
  AppBar _buildAppBar(bool isBuyingMode, AppModeProvider appModeProvider) { /* ... Same as before ... */
      return AppBar(
      backgroundColor: const Color(0xFF267873),
      title: Text(isBuyingMode ? 'My E-Commerce App' : 'Seller Dashboard', style: GoogleFonts.irishGrover(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _navigateToSearch),
        if (!isBuyingMode)
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _navigateToAddProduct),
        TextButton(
          onPressed: () => appModeProvider.switchTo(isBuyingMode ? AppMode.selling : AppMode.buying),
          child: Text(isBuyingMode ? 'Switch to Selling' : 'Switch to Buying', style: GoogleFonts.irishGrover(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
      ],
    );
  }
  BottomNavigationBar _buildBottomNavBar() { /* ... Same as before ... */ 
      return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF267873), unselectedItemColor: Colors.grey,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'), BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'My Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      currentIndex: _selectedIndex, onTap: _onItemTapped,
    );
  }
}

class SellerPendingApprovalScreen extends StatelessWidget {
  const SellerPendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext context) { /* ... Same as before ... */ 
      return Scaffold(
      appBar: AppBar(title: const Text('Profile Under Review'), backgroundColor: const Color(0xFF267873), foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: () async => await Supabase.instance.client.auth.signOut()),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh Status', onPressed: () => context.read<UserRoleProvider>().fetchUserProfile()), // ✅ FIX: Wapas purana naam
        ],
      ),
      body: Container(color: const Color(0xFFE0F7F5), padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.hourglass_top_rounded, size: 80, color: Colors.orange[700]),
              const SizedBox(height: 20),
              const Text('Verification in Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Your seller profile is under review. This usually takes 24-48 hours.\n\nYou will be able to access the seller dashboard once your profile is approved.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag), label: const Text('Continue Shopping as a Buyer'),
                onPressed: () => context.read<AppModeProvider>().switchTo(AppMode.buying),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF267873), foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}