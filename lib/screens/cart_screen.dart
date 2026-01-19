// lib/screens/cart_screen.dart - COMPLETE REPLACEMENT WITH PAYMENT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../services/payment_service.dart';
import 'coupons_screen.dart';
import 'payment_method_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _appliedCoupon;
  double _discount = 0.0;
  String _selectedPaymentMethod = 'cod';
  bool _isProcessing = false;

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

  Future<void> _selectPaymentMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          selectedMethod: _selectedPaymentMethod,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedPaymentMethod = result);
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    if (cart.items.isEmpty) {
      _showMessage('Cart is empty', Colors.red);
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Processing Payment...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final finalAmount = cart.totalAmount - _discount;
      
      final result = await _paymentService.processPayment(
        items: cart.getOrderItems(),
        total: finalAmount,
        paymentMethod: _selectedPaymentMethod,
      );

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        await cart.clearCart();
        setState(() {
          _appliedCoupon = null;
          _discount = 0.0;
          _isProcessing = false;
        });
        
        _showSuccessDialog(result['orderId'], result['transactionId']);
      } else {
        setState(() => _isProcessing = false);
        _showMessage(result['message'] ?? 'Payment failed', Colors.red);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      setState(() => _isProcessing = false);
      _showMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSuccessDialog(String orderId, String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order ID:'),
                      Text(
                        '#${orderId.substring(orderId.length - 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaction ID:'),
                      Text(
                        transactionId.substring(0, 12),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your order is being prepared',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                                        onPressed: _isProcessing ? null : () {
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
                                        onPressed: _isProcessing ? null : () {
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
                              onPressed: _isProcessing ? null : () => cart.removeItem(menuItem.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Coupon Section
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
                        onPressed: _isProcessing ? null : _removeCoupon,
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
                          onPressed: _isProcessing ? null : () => _applyCoupon(context),
                          icon: const Icon(Icons.local_offer),
                          label: const Text('Apply Coupon'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Payment Method Selection
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _selectPaymentMethod,
                        icon: const Icon(Icons.payment),
                        label: Text(_getPaymentMethodName()),
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
                          onPressed: _isProcessing ? null : () => _placeOrder(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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

  String _getPaymentMethodName() {
    switch (_selectedPaymentMethod) {
      case 'cod':
        return 'Cash on Delivery 💵';
      case 'upi':
        return 'UPI Payment 📱';
      case 'card':
        return 'Card Payment 💳';
      case 'wallet':
        return 'Wallet Payment 👛';
      default:
        return 'Select Payment Method';
    }
  }
}