// lib/screens/analytics_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_ecommerce_app/products/add_product_screen.dart';
import 'package:my_ecommerce_app/products/manage_products_screen.dart';
import 'package:my_ecommerce_app/services/analytics_service.dart';
import 'package:my_ecommerce_app/model/analytics_data.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  AnalyticsDashboardScreenState createState() => AnalyticsDashboardScreenState();
}

class AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final role = context.read<UserRoleProvider>().role;
    final data = await _analyticsService.fetchAnalytics(role);
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserRoleProvider>().role;
    final name = context.watch<UserRoleProvider>().fullName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildWelcomeHeader(name, role),
                    const SizedBox(height: 24),
                    _buildBody(role),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBody(String? role) {
    if (_analyticsData == null) {
      return const Center(child: Text('Could not load analytics.'));
    }
    
    if (role == 'seller') {
      return _buildSellerDashboard(_analyticsData!);
    } else {
      return Center(child: Text("Welcome, ${role ?? 'User'}!"));
    }
  }

  Widget _buildWelcomeHeader(String name, String? role) {
    final title = (role == 'seller') ? "Welcome Back, $name!" : "Dashboard";
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF267873)));
  }

  Widget _buildSellerDashboard(AnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
          // ✅ FIX #1: Card ko zyada height di gayi hai taaki content fit ho sake
          childAspectRatio: 1.25,
          children: [
            _buildAnalyticsCard(icon: Icons.currency_rupee, title: 'Total Sales', value: '₹${data.totalSales.toStringAsFixed(0)}', color: Colors.green),
            _buildAnalyticsCard(icon: Icons.new_releases_outlined, title: 'New Orders', value: data.newOrdersCount.toString(), color: Colors.orange),
          ],
        ),
        const SizedBox(height: 30),
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('Add a New Product'), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen()))),
        ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Manage All Products'), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageProductsScreen()))),
      ],
    );
  }
  
  // ✅ FIX #2: Card ke andar ke layout ko poori tarah se badal diya gaya hai taaki woh overflow na ho.
  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Yeh content ko aapas mein aaram se distribute karega
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox.shrink(), // Chhota sa spacer taaki neeche ka content aaram se fit ho
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FittedBox text ko automatically chhota kar dega agar jagah kam ho
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}