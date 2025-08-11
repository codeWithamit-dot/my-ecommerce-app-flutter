// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/main.dart';
import 'package:my_ecommerce_app/products/add_product_screen.dart';
import 'package:my_ecommerce_app/products/manage_products_screen.dart';
import 'package:my_ecommerce_app/profile/create_buyer_profile_screen.dart';
import 'package:my_ecommerce_app/profile/create_seller_profile_screen.dart';
import 'package:my_ecommerce_app/profile/view_profile_screen.dart';
import 'package:my_ecommerce_app/providers/app_mode_provider.dart'; // <<<--- YAHAN GALTI THEEK KI GAYI HAI
import 'package:my_ecommerce_app/splash_screen.dart'; // <<<--- YAHAN GALTI THEEK KI GAYI HAI
import 'package:provider/provider.dart';

class DynamicHomePage extends StatelessWidget {
  const DynamicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModeProvider>(
      builder: (context, appModeProvider, child) {
        return appModeProvider.mode == AppMode.buying
            ? const BuyerDashboard()
            : const SellerDashboard();
      },
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("My Orders will be listed here."));
  }
}

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.indigo),
          SizedBox(height: 20),
          Text("Welcome, Buyer!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Browse our amazing products here.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        ],
      ),
    ));
  }
}

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildStatsSection(context),
          const SizedBox(height: 24),
          _buildActionButton(
            context: context,
            icon: Icons.add_circle_outline,
            label: 'Add a New Product',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.inventory_2_outlined,
            label: 'Manage My Products',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context: context,
            icon: Icons.receipt_long_outlined,
            label: 'View Incoming Orders',
            onTap: () { 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller Orders page to be built.')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, 'Total Sales', '₹0'),
            _buildStatItem(context, 'Orders', '0'),
            _buildStatItem(context, 'Products', '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  
  Widget _buildActionButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios),
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DynamicHomePage(),
    OrdersPage(),
  ];

  void _navigateToProfile() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final appMode = context.read<AppModeProvider>().mode;
    final userId = supabase.auth.currentUser!.id;

    try {
      final profileColumn = appMode == AppMode.buying
          ? 'is_buyer_profile_complete'
          : 'is_seller_profile_complete';

      final response = await supabase
          .from('profiles')
          .select(profileColumn)
          .eq('id', userId)
          .maybeSingle();
      final isProfileComplete = (response?[profileColumn] as bool?) ?? false;

      if (mounted) {
        if (isProfileComplete) {
          navigator.push(
              MaterialPageRoute(builder: (_) => const ViewProfileScreen()));
        } else {
          if (appMode == AppMode.buying) {
            navigator.push(MaterialPageRoute(
                builder: (_) => const CreateBuyerProfileScreen()));
          } else {
            navigator.push(MaterialPageRoute(
                builder: (_) => const CreateSellerProfileScreen()));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _navigateToProfile();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await supabase.auth.signOut();
    if (mounted) {
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModeProvider>(
      builder: (context, appModeProvider, child) {
        final isBuyingMode = appModeProvider.mode == AppMode.buying;

        return Scaffold(
          appBar: AppBar(
            title:
                Text(isBuyingMode ? 'My E-Commerce App' : 'Seller Dashboard'),
            actions: [
              TextButton(
                onPressed: () => appModeProvider
                    .switchTo(isBuyingMode ? AppMode.selling : AppMode.buying),
                child: Text(
                  isBuyingMode ? 'Become a Seller' : 'Switch to Buying',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: _logout,
              ),
            ],
          ),
          body: _pages.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'My Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}