// lib/services/review_service.dart - ENHANCED WITH EMOJI SENTIMENT
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ReviewService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  // ✅ CHECK ELIGIBILITY
  Future<Map<String, dynamic>> checkEligibility(String orderId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/eligibility/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'eligible': false, 'message': 'Failed to check eligibility'};
    } catch (e) {
      print('Check eligibility error: $e');
      return {'eligible': false, 'message': 'Network error'};
    }
  }

  // ✅ SUBMIT REVIEW (with emoji sentiment)
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required String emojiSentiment, // ✅ NEW: thumbs_up or thumbs_down
    required double rating,
    required double foodQualityRating,
    required double deliveryRating,
    required String reviewText,
    List<String>? photos,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'emoji_sentiment': emojiSentiment, // ✅ NEW
          'rating': rating,
          'food_quality_rating': foodQualityRating,
          'delivery_rating': deliveryRating,
          'review_text': reviewText,
          'photos': photos ?? [],
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      print('Submit review error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ✅ GET RESTAURANT REVIEWS
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId, {
    String sort = 'recent',
    int minTrustScore = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/reviews/restaurant/$restaurantId?sort=$sort&minTrustScore=$minTrustScore',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reviews']);
      }
      return [];
    } catch (e) {
      print('Get reviews error: $e');
      return [];
    }
  }

  // ✅ MARK HELPFUL
  Future<bool> markHelpful(String reviewId, bool isHelpful) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$reviewId/helpful'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'is_helpful': isHelpful,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark helpful error: $e');
      return false;
    }
  }

  // ✅ REPORT REVIEW
  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$reviewId/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Report review error: $e');
      return false;
    }
  }

  // ✅ GET MY REVIEWS
  Future<List<Map<String, dynamic>>> getMyReviews() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/my-reviews'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print('Get my reviews error: $e');
      return [];
    }
  }

  // ✅ GET REVIEWER PROFILE
  Future<Map<String, dynamic>?> getReviewerProfile() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/reviewer-profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get reviewer profile error: $e');
      return null;
    }
  }
}
