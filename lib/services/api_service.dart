// lib/services/api_service.dart - FIXED (REMOVE DUPLICATE AuthService)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../config/api_config.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import 'auth_service.dart'; // ✅ Import from auth_service.dart

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

  // ✅ Get restaurant owner's restaurant
  Future<Restaurant?> getMyRestaurant() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/my-restaurant'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Restaurant.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get my restaurant error: $e');
      return null;
    }
  }

  // ✅ Create restaurant
  Future<bool> createRestaurant(Map<String, dynamic> restaurantData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(restaurantData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create restaurant error: $e');
      return false;
    }
  }

  // ✅ Update restaurant
  Future<bool> updateRestaurant(String restaurantId, Map<String, dynamic> restaurantData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/restaurants/$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(restaurantData),
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
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard?timeRange=$timeRange'),
        headers: {
          'Authorization': 'Bearer $token',
        },
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

  Future<bool> updateRestaurantImage(String restaurantId, String imageUrl) async {
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
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
      );
      
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

      return response.statusCode == 201;
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

      return response.statusCode == 200;
    } catch (e) {
      print('Update menu error: $e');
      return false;
    }
  }

  Future<bool> deleteMenuItem(String menuId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$menuId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Delete menu error: $e');
      return false;
    }
  }

  // ==================== ORDERS ====================
  
  Future<bool> placeOrder(List<Map<String, dynamic>> items, double total) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items,
          'total': total,
        }),
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
      
      if (token == null || token.isEmpty) {
        print('Upload error: No authentication token');
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      final filename = imageFile.path.split('/').last;
      MediaType? contentType;
      
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (filename.toLowerCase().endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: filename,
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData['imageUrl'];
        } catch (e) {
          print('JSON parse error: $e');
          return null;
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ✅ Upload video
  Future<String?> uploadVideo(File videoFile) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null || token.isEmpty) {
        print('Upload error: No authentication token');
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload-video'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      final filename = videoFile.path.split('/').last;
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: filename,
          contentType: MediaType('video', 'mp4'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData['videoUrl'];
        } catch (e) {
          print('JSON parse error: $e');
          return null;
        }
      } else {
        print('Video upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Video upload error: $e');
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
        final data = json.decode(response.body);
        await _authService.saveUserData(data['user']);
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
        final data = json.decode(response.body);
        await _authService.saveUserData(data['user']);
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
        final data = json.decode(response.body);
        await _authService.saveUserData(data['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}