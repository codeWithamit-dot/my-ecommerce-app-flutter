// Path: lib/screens/home_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../products/add_product_screen.dart';
import '../profile/view_profile_screen.dart';
import '../providers/app_mode_provider.dart';
import '../providers/user_role_provider.dart';
import '../role_selection_screen.dart';
import '../products/manage_products_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'cart_manager_screen.dart';
import 'orders_manager_screen.dart';
import 'order_history_screen.dart';
import 'categories_screen.dart';
import 'home_page_content.dart';
import 'search_screen.dart';
import 'seller_reviews_screen.dart';
import 'notification_screen.dart';

class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({super.key});
  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _buyerPages = <Widget>[
    HomePageContent(),
    CategoriesScreen(),
    CartManagerScreen(),
    OrderHistoryScreen(), // Correct screen for buyers
    ViewProfileScreen()
  ];

  static const List<BottomNavigationBarItem> _buyerNavItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Categories'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile')
  ];
  
  static final List<Widget> _sellerPages = <Widget>[
    const AnalyticsDashboardScreen(),
    const ManageProductsScreen(),
    const OrdersManagerScreen(),
    const SellerReviewsScreen(),
    const ViewProfileScreen()
  ];
  
  static const List<BottomNavigationBarItem> _sellerNavItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.rate_review_outlined), label: 'Reviews'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile')
  ];
  
  @override
  void initState() {
    super.initState(); 
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileCompleteness());
  }

  void _checkProfileCompleteness() {
    if (!mounted) return; 
    final profileProvider = context.read<UserRoleProvider>();
    if (!profileProvider.isLoading && profileProvider.role == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), (route) => false);
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    final appModeProvider = context.read<AppModeProvider>();
    final userRoleProvider = context.read<UserRoleProvider>();
    appModeProvider.resetMode();
    userRoleProvider.clearProfile();
    await Supabase.instance.client.auth.signOut();
  }

  void _navigateToAddProduct() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()));
  void _navigateToSearch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    final appModeProvider = context.watch<AppModeProvider>(); 
    final profileProvider = context.watch<UserRoleProvider>();

    if (profileProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (profileProvider.role == null) {
      return const Scaffold(body: Center(child: Text("Loading user profile...")));
    }

    final isBuyingMode = appModeProvider.mode == AppMode.buying; 
    final isSeller = profileProvider.role == 'seller';
    final approvalStatus = profileProvider.approvalStatus;
    
    if (isSeller && !isBuyingMode && approvalStatus == 'pending') {
      return const SellerPendingApprovalScreen();
    }
    
    final List<Widget> currentPages = isSeller && !isBuyingMode ? _sellerPages : _buyerPages;
    
    // ✅✅✅ FIX: Simplified the logic to avoid the type error.
    final List<BottomNavigationBarItem> currentNavItems = isSeller && !isBuyingMode 
        ? _sellerNavItems 
        : _buyerNavItems;

    return Scaffold(
      appBar: _buildAppBar(context, isBuyingMode, isSeller, currentNavItems),
      body: IndexedStack(index: _selectedIndex, children: currentPages),
      bottomNavigationBar: _buildBottomNavBar(currentNavItems));
  }

  AppBar _buildAppBar(BuildContext context, bool isBuyingMode, bool isSeller, List<BottomNavigationBarItem> navItems) {
    final appModeProvider = context.read<AppModeProvider>();
    String appBarTitle = isBuyingMode ? 'My Store' : navItems[_selectedIndex].label ?? 'Seller';
    return AppBar(
      title: Text(appBarTitle),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _navigateToSearch),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
        ),
        if (isSeller && !isBuyingMode)
          IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Add New Product', onPressed: _navigateToAddProduct),
        if (isSeller)
          TextButton(onPressed: () {
              setState(() => _selectedIndex = 0);
              appModeProvider.switchTo(isBuyingMode ? AppMode.selling : AppMode.buying);},
            child: Text(isBuyingMode ? 'Switch to Selling' : 'Switch to Buying', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavBar(List<BottomNavigationBarItem> items) {
    return BottomNavigationBar(
      items: items, 
      currentIndex: _selectedIndex, 
      onTap: _onItemTapped,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    );
  }
}

class SellerPendingApprovalScreen extends StatelessWidget {
  const SellerPendingApprovalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Under Review'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: () async {
            final appModeProvider = context.read<AppModeProvider>();
            final userRoleProvider = context.read<UserRoleProvider>();
            appModeProvider.resetMode();
            userRoleProvider.clearProfile();
            await Supabase.instance.client.auth.signOut();
          }),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh Status', onPressed: () => context.read<UserRoleProvider>().fetchUserProfile()),
        ],
      ),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.hourglass_top_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text('Verification in Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Your seller profile is under review.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag), 
                label: const Text('Continue as a Buyer'),
                onPressed: () => context.read<AppModeProvider>().switchTo(AppMode.buying),
              ),
      ]))
    );
  }
}