import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu.dart';
import '../models/order.dart';
import 'auth_service.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:5000';
  // static const String baseUrl = 'http://10.0.2.2:5000';
  static const String baseUrl = 'http://10.0.2.2:5001';
  final AuthService _authService = AuthService();

  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  Future<List<MenuItem>> getMenu(String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => MenuItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching menu: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> placeOrder(
      List<OrderItem> items, double total) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items.map((i) => i.toJson()).toList(),
          'total': total,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Order placed successfully'};
      } else {
        return {'success': false, 'message': 'Failed to place order'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<Order>> getOrderHistory() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }
}