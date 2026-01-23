// lib/services/payment_service.dart - COMPLETE REPLACEMENT
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'notification_service.dart'; // ✅ ADD THIS

class PaymentService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService =
      NotificationService(); // ✅ ADD THIS

  // Process payment and create order
  Future<Map<String, dynamic>> processPayment({
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
  }) async {
    try {
      final token = await _authService.getToken();

      // Step 1: Initiate payment
      final paymentResponse = await http.post(
        Uri.parse('$baseUrl/payments/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': total,
          'paymentMethod': paymentMethod,
        }),
      );

      if (paymentResponse.statusCode != 200) {
        return {
          'success': false,
          'message': 'Payment initiation failed',
        };
      }

      final paymentData = jsonDecode(paymentResponse.body);
      final transactionId = paymentData['transactionId'];

      // Step 2: Create order with payment reference
      final orderResponse = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items,
          'total': total,
          'transactionId': transactionId,
        }),
      );

      if (orderResponse.statusCode == 201) {
        final orderId = jsonDecode(orderResponse.body)['order']['_id'];

        // ✅ ADD NOTIFICATION AFTER SUCCESSFUL ORDER
        String restaurantName = 'Restaurant';
        if (items.isNotEmpty && items[0]['name'] != null) {
          restaurantName = items[0]['restaurantName'] ?? 'Restaurant';
        }

        await _notificationService.addNotification(
          title: 'Order Placed Successfully! 🎉',
          message:
              'Your order from $restaurantName has been placed. Track it in order history.',
          orderId: orderId,
          restaurantName: restaurantName,
        );

        return {
          'success': true,
          'orderId': orderId,
          'transactionId': transactionId,
        };
      }

      // Rollback payment if order creation fails
      await _rollbackPayment(transactionId);

      return {
        'success': false,
        'message': 'Order creation failed',
      };
    } catch (e) {
      print('Payment processing error: $e');
      return {
        'success': false,
        'message': 'Payment processing error: $e',
      };
    }
  }

  Future<void> _rollbackPayment(String transactionId) async {
    try {
      final token = await _authService.getToken();
      await http.post(
        Uri.parse('$baseUrl/payments/rollback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'transactionId': transactionId}),
      );
    } catch (e) {
      print('Payment rollback error: $e');
    }
  }

  // Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    return [
      {
        'id': 'cod',
        'name': 'Cash on Delivery',
        'icon': '💵',
        'description': 'Pay when you receive your order',
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'icon': '📱',
        'description': 'Pay using UPI apps',
      },
      {
        'id': 'card',
        'name': 'Credit/Debit Card',
        'icon': '💳',
        'description': 'Pay using your card',
      },
      {
        'id': 'wallet',
        'name': 'Wallet',
        'icon': '👛',
        'description': 'Pay using digital wallet',
      },
    ];
  }

  // Verify payment status
  Future<bool> verifyPayment(String transactionId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/verify/$transactionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'Success';
      }
      return false;
    } catch (e) {
      print('Payment verification error: $e');
      return false;
    }
  }
}
