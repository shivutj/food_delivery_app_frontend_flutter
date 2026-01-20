// lib/screens/restaurant_offers_screen.dart - DEMO OFFERS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/restaurant.dart';

class RestaurantOffersScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantOffersScreen({super.key, required this.restaurant});

  // Demo offers specific to restaurant
  List<Map<String, dynamic>> get _offers => [
    {
      'code': 'DINE20',
      'title': '20% Off Dine-In',
      'description': 'Get 20% off when you dine at ${restaurant.name}',
      'discount': '20%',
      'type': 'Dine-In',
      'minOrder': 0,
      'color': Colors.orange,
      'icon': Icons.restaurant,
    },
    {
      'code': 'DELIVERY15',
      'title': '15% Off Delivery',
      'description': 'Save 15% on delivery orders above ₹299',
      'discount': '15%',
      'type': 'Delivery',
      'minOrder': 299,
      'color': Colors.blue,
      'icon': Icons.delivery_dining,
    },
    {
      'code': 'WEEKEND30',
      'title': 'Weekend Special',
      'description': '30% off on weekends (Sat-Sun)',
      'discount': '30%',
      'type': 'All',
      'minOrder': 199,
      'color': Colors.purple,
      'icon': Icons.celebration,
    },
    {
      'code': 'COMBO50',
      'title': 'Combo Deal',
      'description': 'Buy 2 Get 1 Free on selected items',
      'discount': 'BOGO',
      'type': 'Special',
      'minOrder': 0,
      'color': Colors.green,
      'icon': Icons.local_offer,
    },
  ];

  void _copyCoupon(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon "$code" copied! 🎉'),
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
        title: const Text('Special Offers'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: Column(
        children: [
          // Restaurant Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Exclusive offers just for you!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Offers List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                return _buildOfferCard(context, offer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              offer['color'].withOpacity(0.15),
              offer['color'].withOpacity(0.05),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: offer['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      offer['icon'],
                      color: offer['color'],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: offer['color'],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer['type'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: offer['color'],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      offer['discount'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                offer['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: offer['color'],
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            offer['code'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: offer['color'],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _copyCoupon(context, offer['code']),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('COPY'),
                      style: TextButton.styleFrom(
                        foregroundColor: offer['color'],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (offer['minOrder'] > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Min. order: ₹${offer['minOrder']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}