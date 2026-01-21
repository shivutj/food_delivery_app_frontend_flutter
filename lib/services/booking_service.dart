// lib/services/booking_service.dart - DINE-IN BOOKING SERVICE
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class BookingService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createBooking({
    required String restaurantId,
    required DateTime bookingDate,
    required String timeSlot,
    required int numberOfGuests,
    String? specialRequests,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/dine-in-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'booking_date': bookingDate.toIso8601String(),
          'time_slot': timeSlot,
          'number_of_guests': numberOfGuests,
          'special_requests': specialRequests ?? '',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'booking': data['booking'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Booking failed',
        };
      }
    } catch (e) {
      print('Create booking error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/dine-in-bookings/my-bookings'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get my bookings error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantBookings() async {
    try {
      final token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/dine-in-bookings/restaurant'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get restaurant bookings error: $e');
      return [];
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final token = await _authService.getToken();
      
      final response = await http.patch(
        Uri.parse('$baseUrl/dine-in-bookings/$bookingId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update booking status error: $e');
      return false;
    }
  }
}