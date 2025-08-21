// Path: lib/screens/promotions/manage_coupons_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ecommerce_app/model/coupon_model.dart';
import 'package:my_ecommerce_app/services/coupon_service.dart';
import 'create_coupon_screen.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  final CouponService _couponService = CouponService();
  late Future<List<Coupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCoupons();
  }

  Future<void> _refreshCoupons() async {
    setState(() {
      _couponsFuture = _couponService.fetchMySellerCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Coupons'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCoupons,
        child: FutureBuilder<List<Coupon>>(
          future: _couponsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final coupons = snapshot.data ?? [];
            if (coupons.isEmpty) {
              return const Center(child: Text("You haven't created any coupons yet."));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: coupons.length,
              itemBuilder: (context, index) {
                return _buildCouponCard(coupons[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create Coupon'),
        onPressed: () async {
          final bool? couponCreated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateCouponScreen()),
          );
          if (couponCreated == true && mounted) {
            _refreshCoupons();
          }
        },
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final bool isExpired = coupon.validUntil != null && coupon.validUntil!.isBefore(DateTime.now());
    final bool isActiveAndNotExpired = coupon.isActive && !isExpired;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Switch(
                  value: isActiveAndNotExpired,
                  onChanged: isExpired ? null : (value) async {
                    await _couponService.updateCouponStatus(coupon.id, value);
                    _refreshCoupons();
                  },
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              'Discount:',
              coupon.discountType == 'percentage'
                  ? '${coupon.discountValue}% Off'
                  : '₹${coupon.discountValue.toStringAsFixed(0)} Off'
            ),
            if (coupon.minPurchaseAmount > 0)
              _buildInfoRow('Min. Purchase:', '₹${coupon.minPurchaseAmount.toStringAsFixed(0)}'),
            if (coupon.validUntil != null)
              _buildInfoRow(
                'Expires:',
                DateFormat('d MMM, yyyy').format(coupon.validUntil!),
                textColor: isExpired ? Colors.red : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$title ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}