// lib/screens/support/support_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:my_ecommerce_app/providers/user_role_provider.dart';
import 'package:provider/provider.dart';
import 'admin_threads_screen.dart';
import 'user_threads_screen.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provider
    final userRole = Provider.of<UserRoleProvider>(context).role;

    // Show a loading indicator while the role is being fetched
    if (userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Based on the role, return the appropriate screen
    if (userRole == 'admin') {
      return const AdminThreadsScreen();
    } else {
      return const UserThreadsScreen();
    }
  }
}