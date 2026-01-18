// lib/screens/cart_screen.dart - WITH COUPON SUPPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'coupons_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _appliedCoupon;
  double _discount = 0.0;

  void _applyCoupon(BuildContext context) {
    final couponController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Coupon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: couponController,
              decoration: const InputDecoration(
                hintText: 'Enter coupon code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CouponsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.local_offer),
              label: const Text('View Available Coupons'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = couponController.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                _validateAndApplyCoupon(code);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _validateAndApplyCoupon(String code) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // ✅ Simple coupon validation (MVP)
    if (code == 'FIRST50' && cart.totalAmount >= 199) {
      setState(() {
        _appliedCoupon = code;
        _discount = cart.totalAmount * 0.5;
      });
      _showMessage('Coupon applied! 50% off 🎉', Colors.green);
    } else if (code == 'SAVE100' && cart.totalAmount >= 500) {
      setState(() {
        _appliedCoupon = code;
        _discount = 100;
      });
      _showMessage('Coupon applied! ₹100 off 🎉', Colors.green);
    } else if (code == 'WEEKEND' && cart.totalAmount >= 299) {
      setState(() {
        _appliedCoupon = code;
        _discount = cart.totalAmount * 0.3;
      });
      _showMessage('Coupon applied! 30% off 🎉', Colors.green);
    } else {
      _showMessage('Invalid coupon or minimum order not met', Colors.red);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discount = 0.0;
    });
    _showMessage('Coupon removed', Colors.orange);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    if (cart.items.isEmpty) {
      _showMessage('Cart is empty', Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final apiService = ApiService();
    final finalAmount = cart.totalAmount - _discount;
    
    final success = await apiService.placeOrder(
      cart.getOrderItems(),
      finalAmount,
    );

    Navigator.pop(context);

    if (success) {
      // ✅ Clear cart ONLY after successful order
      await cart.clearCart();
      setState(() {
        _appliedCoupon = null;
        _discount = 0.0;
      });
      
      _showMessage('Order placed successfully! 🎉', Colors.green);
      Navigator.pop(context);
    } else {
      _showMessage('Failed to place order', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final finalAmount = cart.totalAmount - _discount;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final cartItem = cart.items.values.toList()[index];
                    final menuItem = cartItem.menuItem;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: menuItem.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menuItem.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${menuItem.price}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          if (cartItem.quantity > 1) {
                                            cart.updateQuantity(
                                              menuItem.id,
                                              cartItem.quantity - 1,
                                            );
                                          } else {
                                            cart.removeItem(menuItem.id);
                                          }
                                        },
                                        iconSize: 28,
                                      ),
                                      Text(
                                        '${cartItem.quantity}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          cart.updateQuantity(
                                            menuItem.id,
                                            cartItem.quantity + 1,
                                          );
                                        },
                                        iconSize: 28,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => cart.removeItem(menuItem.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ Coupon Section
              if (_appliedCoupon != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coupon "$_appliedCoupon" applied',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'You save ₹${_discount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _removeCoupon,
                      ),
                    ],
                  ),
                ),

              // Bottom Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Apply Coupon Button
                      if (_appliedCoupon == null)
                        OutlinedButton.icon(
                          onPressed: () => _applyCoupon(context),
                          icon: const Icon(Icons.local_offer),
                          label: const Text('Apply Coupon'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Price Breakdown
                      if (_discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal:',
                                style: TextStyle(color: Colors.grey.shade700)),
                            Text('₹${cart.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount:',
                                style: TextStyle(color: Colors.green.shade700)),
                            Text('- ₹${_discount.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${finalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Place Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _placeOrder(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}