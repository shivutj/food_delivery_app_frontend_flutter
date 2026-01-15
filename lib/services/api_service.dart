// lib/services/api_service.dart - Updated with admin functions
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu.dart';
import '../models/order.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
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

  // Admin functions
  Future<List<Order>> getAllOrders() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Status updated'};
      } else {
        return {'success': false, 'message': 'Failed to update status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addMenuItem(String restaurantId, String name,
      double price, String category, String image) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'category': category,
          'image': image,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Menu item added'};
      } else {
        return {'success': false, 'message': 'Failed to add item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMenuItem(String menuId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$menuId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Item deleted'};
      } else {
        return {'success': false, 'message': 'Failed to delete item'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}