// lib/services/api_service.dart - OPTIMIZED
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Common headers
  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== RESTAURANTS ====================

  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .map((json) => Restaurant.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get restaurants error: $e');
      return [];
    }
  }

  Future<Restaurant?> getMyRestaurant() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/my-restaurant'),
        headers: await _authHeaders(),
      );
      return response.statusCode == 200
          ? Restaurant.fromJson(jsonDecode(response.body))
          : null;
    } catch (e) {
      print('Get my restaurant error: $e');
      return null;
    }
  }

  Future<bool> createRestaurant(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants'),
        headers: await _authHeaders(),
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create restaurant error: $e');
      return false;
    }
  }

  Future<bool> updateRestaurant(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: await _authHeaders(),
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update restaurant error: $e');
      return false;
    }
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>?> getAnalytics(String timeRange) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard?timeRange=$timeRange'),
        headers: await _authHeaders(),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      print('Get analytics error: $e');
      return null;
    }
  }

  Future<bool> updateRestaurantImage(String id, String imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/restaurants/$id/image'),
        headers: await _authHeaders(),
        body: json.encode({'image': imageUrl}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update restaurant image error: $e');
      return false;
    }
  }

  // ==================== MENU ====================

  Future<List<MenuItem>> getMenu(String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
      );
      return response.statusCode == 200
          ? (jsonDecode(response.body) as List)
              .map((json) => MenuItem.fromJson(json))
              .toList()
          : [];
    } catch (e) {
      print('Get menu error: $e');
      return [];
    }
  }

  Future<bool> addMenuItem(MenuItem item) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/menu'),
        headers: await _authHeaders(),
        body: json.encode(item.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Add menu error: $e');
      return false;
    }
  }

  Future<bool> updateMenuItem(String id, MenuItem item) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/menu/$id'),
        headers: await _authHeaders(),
        body: json.encode(item.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update menu error: $e');
      return false;
    }
  }

  Future<bool> deleteMenuItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$id'),
        headers: await _authHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete menu error: $e');
      return false;
    }
  }

  // ==================== ORDERS ====================

  Future<bool> placeOrder(
      List<Map<String, dynamic>> items, double total) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _authHeaders(),
        body: jsonEncode({'items': items, 'total': total}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Place order error: $e');
      return false;
    }
  }

  Future<List<Order>> getOrderHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/history'),
        headers: await _authHeaders(),
      );
      return response.statusCode == 200
          ? (jsonDecode(response.body) as List)
              .map((json) => Order.fromJson(json))
              .toList()
          : [];
    } catch (e) {
      print('Get order history error: $e');
      return [];
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/all'),
        headers: await _authHeaders(),
      );
      return response.statusCode == 200
          ? (jsonDecode(response.body) as List)
              .map((json) => Order.fromJson(json))
              .toList()
          : [];
    } catch (e) {
      print('Get all orders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$id/status'),
        headers: await _authHeaders(),
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update order status error: $e');
      return false;
    }
  }

  // ==================== UPLOADS ====================

  Future<String?> uploadImage(File file) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload'),
      )..headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final response = await http.Response.fromStream(await request.send());

      return response.statusCode == 200
          ? json.decode(response.body)['imageUrl']
          : null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<String?> uploadVideo(File file) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload-video'),
      )..headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath('video', file.path));
      final response = await http.Response.fromStream(await request.send());

      return response.statusCode == 200
          ? json.decode(response.body)['videoUrl']
          : null;
    } catch (e) {
      print('Video upload error: $e');
      return null;
    }
  }

  // ==================== PROFILE ====================

  Future<bool> updateProfilePhoto(String url) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/photo'),
        headers: await _authHeaders(),
        body: json.encode({'profilePhoto': url}),
      );
      if (response.statusCode == 200) {
        await _authService.saveUserData(json.decode(response.body)['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile photo error: $e');
      return false;
    }
  }

  Future<bool> updateAddress({
    required String street,
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/address'),
        headers: await _authHeaders(),
        body: json.encode({
          'street': street,
          'city': city,
          'state': state,
          'pincode': pincode,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      if (response.statusCode == 200) {
        await _authService.saveUserData(json.decode(response.body)['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Update address error: $e');
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final response = await http.patch(
        Uri.parse('$baseUrl/profile'),
        headers: await _authHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        await _authService.saveUserData(json.decode(response.body)['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}
