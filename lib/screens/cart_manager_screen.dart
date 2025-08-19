// lib/screens/cart_manager_screen.dart

import 'package:flutter/material.dart';
import 'cart_screen.dart';

// Yeh screen ab ek 'gatekeeper' ki tarah hai, jo seedha asli CartScreen ko kholti hai.
class CartManagerScreen extends StatelessWidget {
  const CartManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Iska apna UI nahi hai. Yeh ek "Scaffoldless" widget hai.
    return const CartScreen();
  }
}