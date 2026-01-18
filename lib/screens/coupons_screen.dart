// lib/screens/coupons_screen.dart - DEMO COUPONS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  // ✅ Demo coupons (MVP)
  static const List<Map<String, dynamic>> _coupons = [
    {
      'code': 'FIRST50',
      'title': '50% Off First Order',
      'description': 'Get 50% off on your first order',
      'discount': '50%',
      'minOrder': 199,
      'color': Colors.orange,
    },
    {
      'code': 'SAVE100',
      'title': '₹100 Off',
      'description': 'Save ₹100 on orders above ₹500',
      'discount': '₹100',
      'minOrder': 500,
      'color': Colors.green,
    },
    {
      'code': 'WEEKEND',
      'title': 'Weekend Special',
      'description': '30% off on weekend orders',
      'discount': '30%',
      'minOrder': 299,
      'color': Colors.purple,
    },
  ];

  void _copyCoupon(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon code "$code" copied! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons & Offers'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _coupons.length,
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          return _buildCouponCard(context, coupon);
        },
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              coupon['color'].withOpacity(0.1),
              coupon['color'].withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: coupon['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: coupon['color'],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          coupon['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: coupon['color'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      coupon['discount'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: coupon['color'],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            coupon['code'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: coupon['color'],
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _copyCoupon(context, coupon['code']),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('COPY'),
                      style: TextButton.styleFrom(
                        foregroundColor: coupon['color'],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Min. order: ₹${coupon['minOrder']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}