// lib/services/auth_service.dart - UPDATED WITH ID VERIFICATION
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        await saveUserData(data['user']);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
        };
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'requiresOTP': data['requiresOTP'],
          'userId': data['userId'],
          'message': data['message'],
          'otp': data['otp'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // REGISTER with OTP and ID verification
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
    String role, {
    String? idType,
    String? idNumber,
  }) async {
    try {
      // Frontend validation
      if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
        return {
          'success': false,
          'message': 'Phone number must be exactly 10 digits',
        };
      }

      // ✅ Validate ID for restaurant owners
      if (role == 'restaurant') {
        if (idType == null || idNumber == null) {
          return {
            'success': false,
            'message': 'ID verification is required for restaurant owners',
          };
        }

        if (idType == 'pan') {
          final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
          if (!panRegex.hasMatch(idNumber)) {
            return {
              'success': false,
              'message': 'Invalid PAN format',
            };
          }
        } else if (idType == 'aadhaar') {
          if (idNumber.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(idNumber)) {
            return {
              'success': false,
              'message': 'Invalid Aadhaar format',
            };
          }
        }
      }

      final body = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };

      // ✅ Add ID verification fields
      if (role == 'restaurant' && idType != null && idNumber != null) {
        body['idType'] = idType;
        body['idNumber'] = idNumber;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'userId': data['userId'],
          'otp': data['otp'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // VERIFY OTP
  Future<Map<String, dynamic>> verifyOTP(String userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // RESEND OTP
  Future<Map<String, dynamic>> resendOTP(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'otp': data['otp'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // TOKEN AND USER DATA STORAGE
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}