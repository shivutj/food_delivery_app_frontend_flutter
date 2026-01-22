// lib/services/admin_review_service.dart - HTTP-based admin reviews
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminReviewService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getReviewAnalytics(
      {String timeRange = 'last30days'}) async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/admin/reviews/analytics?timeRange=$timeRange'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      print('Analytics error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getFlaggedReviews() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/flagged'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['flagged_reviews']);
      }

      return [];
    } catch (e) {
      print('Get flagged reviews error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllReviews({int limit = 50}) async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/all?limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reviews']);
      }

      return [];
    } catch (e) {
      print('Get all reviews error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/stats/overview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      print('Get review stats error: $e');
      return {};
    }
  }

  Future<bool> approveReview(String reviewId) async {
    try {
      final token = await _authService.getToken();

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/$reviewId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'notes': 'Approved by admin'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Approve review error: $e');
      return false;
    }
  }

  Future<bool> hideReview(String reviewId, String reason) async {
    try {
      final token = await _authService.getToken();

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/$reviewId/hide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Hide review error: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId, String reason) async {
    try {
      final token = await _authService.getToken();

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete review error: $e');
      return false;
    }
  }

  Future<bool> banReviewer(String userId, String reason,
      {int durationDays = 30}) async {
    try {
      final token = await _authService.getToken();

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/reviewer/$userId/ban'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ban': true,
          'reason': reason,
          'duration_days': durationDays,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Ban reviewer error: $e');
      return false;
    }
  }

  Future<bool> unbanReviewer(String userId) async {
    try {
      final token = await _authService.getToken();

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/admin/reviews/reviewer/$userId/ban'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ban': false}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Unban reviewer error: $e');
      return false;
    }
  }
}
