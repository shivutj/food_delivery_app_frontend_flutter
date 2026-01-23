// lib/services/review_service.dart - User review service
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import 'auth_service.dart';
import 'notification_service.dart'; // ✅ ADDED

class ReviewService {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService =
      NotificationService(); // ✅ ADDED

  Future<Map<String, dynamic>> checkEligibility(String orderId) async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/eligibility/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {'eligible': false, 'message': 'Failed to check eligibility'};
    } catch (e) {
      print('Check eligibility error: $e');
      return {'eligible': false, 'message': 'Error: $e'};
    }
  }

  // ✅ REPLACED submitReview METHOD WITH NOTIFICATION INTEGRATION
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required String emojiSentiment,
    required double rating,
    required double foodQualityRating,
    required double deliveryRating,
    required String reviewText,
    List<String>? photos,
  }) async {
    try {
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'emoji_sentiment': emojiSentiment,
          'rating': rating,
          'food_quality_rating': foodQualityRating,
          'delivery_rating': deliveryRating,
          'review_text': reviewText,
          'photos': photos ?? [],
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final coinsEarned = data['review']?['coins_rewarded'] ?? 0;

        await _notificationService.addNotification(
          title: 'Review Submitted! 🎉',
          message:
              'Thank you for your feedback! You earned $coinsEarned coins.',
          orderId: orderId,
          coinsEarned: coinsEarned,
        );

        return {
          'success': true,
          'data': data,
        };
      }

      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Failed to submit review',
      };
    } catch (e) {
      print('Submit review error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId, {
    String sort = 'recent',
    int minTrustScore = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/reviews/restaurant/$restaurantId?sort=$sort&minTrustScore=$minTrustScore',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reviews']);
      }

      return [];
    } catch (e) {
      print('Get restaurant reviews error: $e');
      return [];
    }
  }

  Future<bool> markHelpful(String reviewId, bool isHelpful) async {
    try {
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews/$reviewId/helpful'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_helpful': isHelpful}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark helpful error: $e');
      return false;
    }
  }

  Future<bool> reportReview(String reviewId, String reason) async {
    try {
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews/$reviewId/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Report review error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyReviews() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/my-reviews'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(response.body),
        );
      }

      return [];
    } catch (e) {
      print('Get my reviews error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getReviewerProfile() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/reviewer-profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {};
    } catch (e) {
      print('Get reviewer profile error: $e');
      return {};
    }
  }
}
