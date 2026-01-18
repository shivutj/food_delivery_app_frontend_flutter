// lib/services/api_service.dart - FIXED DELETE METHOD
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../config/api_config.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  // ==================== RESTAURANTS ====================

  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get restaurants error: $e');
      return [];
    }
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>?> getAnalytics(String timeRange) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get analytics error: $e');
      return null;
    }
  }

  Future<bool> updateRestaurantImage(
      String restaurantId, String imageUrl) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/restaurants/$restaurantId/image'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final response =
          await http.get(Uri.parse('$baseUrl/restaurants/$restaurantId/menu'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MenuItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get menu error: $e');
      return [];
    }
  }

  Future<bool> addMenuItem(MenuItem menuItem) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/menu'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(menuItem.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Add menu item failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Add menu error: $e');
      return false;
    }
  }

  Future<bool> updateMenuItem(String menuId, MenuItem menuItem) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/menu/$menuId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(menuItem.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Update menu item failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Update menu error: $e');
      return false;
    }
  }

  // ✅ FIXED: Delete menu item with correct endpoint
  Future<bool> deleteMenuItem(String menuId) async {
    try {
      final token = await _authService.getToken();
      
      print('🗑️ Deleting menu item: $menuId');
      print('   Token: ${token?.substring(0, 20)}...');
      print('   URL: $baseUrl/restaurants/menu/$menuId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/restaurants/menu/$menuId'), // ✅ CORRECT ENDPOINT
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('   Response: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete menu error: $e');
      return false;
    }
  }

  // ==================== ORDERS ====================

  Future<bool> placeOrder(
      List<Map<String, dynamic>> items, double total) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get order history error: $e');
      return [];
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get all orders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
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

      return response.statusCode == 200;
    } catch (e) {
      print('Update order status error: $e');
      return false;
    }
  }

  // ==================== IMAGE UPLOAD ====================

  Future<String?> uploadImage(File imageFile) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) return null;

      final filename = imageFile.path.split('/').last;
      MediaType? contentType;

      if (filename.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: filename,
        contentType: contentType,
      ));

      final response =
          await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['imageUrl'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ==================== PROFILE ====================

  Future<bool> updateProfilePhoto(String photoUrl) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/photo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'profilePhoto': photoUrl}),
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
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authService.getToken();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      final response = await http.patch(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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