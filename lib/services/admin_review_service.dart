// lib/services/admin_review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive review analytics
  Future<Map<String, dynamic>> getReviewAnalytics() async {
    try {
      // Fetch all reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      int thumbsUp = 0;
      int thumbsDown = 0;
      Map<String, Map<String, dynamic>> restaurantStats = {};

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final emoji = data['emoji_rating'];
        final restaurantId = data['restaurant_id'];
        final restaurantName = data['restaurant_name'];
        final rating = (data['rating'] ?? 0).toDouble();

        // Count emoji sentiment
        if (emoji == '👍') thumbsUp++;
        if (emoji == '👎') thumbsDown++;

        // Aggregate restaurant stats
        if (!restaurantStats.containsKey(restaurantId)) {
          restaurantStats[restaurantId] = {
            'name': restaurantName,
            'total_rating': 0.0,
            'review_count': 0,
            'thumbs_up': 0,
            'thumbs_down': 0,
          };
        }

        restaurantStats[restaurantId]!['total_rating'] += rating;
        restaurantStats[restaurantId]!['review_count']++;
        if (emoji == '👍') restaurantStats[restaurantId]!['thumbs_up']++;
        if (emoji == '👎') restaurantStats[restaurantId]!['thumbs_down']++;
      }

      // Calculate averages and sort
      final topRestaurants = restaurantStats.entries.map((e) {
        final stats = e.value;
        final avgRating = stats['review_count'] > 0
            ? stats['total_rating'] / stats['review_count']
            : 0.0;

        return {
          'restaurant_id': e.key,
          'name': stats['name'],
          'avg_rating': avgRating,
          'review_count': stats['review_count'],
          'thumbs_up': stats['thumbs_up'],
          'thumbs_down': stats['thumbs_down'],
        };
      }).toList();

      // Sort by average rating descending
      topRestaurants.sort((a, b) =>
          (b['avg_rating'] as double).compareTo(a['avg_rating'] as double));

      final positiveRatio = (thumbsUp + thumbsDown) > 0
          ? thumbsUp / (thumbsUp + thumbsDown)
          : 0.0;

      return {
        'emoji_sentiment': {
          'thumbs_up': thumbsUp,
          'thumbs_down': thumbsDown,
          'positive_ratio': positiveRatio,
        },
        'top_restaurants': topRestaurants.take(10).toList(),
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {
        'emoji_sentiment': {
          'thumbs_up': 0,
          'thumbs_down': 0,
          'positive_ratio': 0.0,
        },
        'top_restaurants': [],
      };
    }
  }

  /// Get all reviews for admin moderation
  Stream<List<Map<String, dynamic>>> getAllReviewsStream() {
    return _firestore
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Delete a review (admin only)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  /// Flag a review for moderation
  Future<void> flagReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'flagged': true,
        'flagged_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error flagging review: $e');
      rethrow;
    }
  }
}
