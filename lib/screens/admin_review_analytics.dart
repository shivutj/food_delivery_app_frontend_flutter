// lib/screens/admin_review_analytics.dart - ADMIN ONLY
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_review_service.dart';

class AdminReviewAnalytics extends StatefulWidget {
  const AdminReviewAnalytics({super.key});

  @override
  State<AdminReviewAnalytics> createState() => _AdminReviewAnalyticsState();
}

class _AdminReviewAnalyticsState extends State<AdminReviewAnalytics> {
  final AdminReviewService _adminService = AdminReviewService();

  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final analytics = await _adminService.getReviewAnalytics();

    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final emojiSentiment = _analytics!['emoji_sentiment'];
    final topRestaurants = _analytics!['top_restaurants'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Analytics'),
        backgroundColor: Colors.purple.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Emoji Sentiment Overview
            _buildSentimentCard(emojiSentiment),
            const SizedBox(height: 24),

            // ✅ Top Restaurants by Ranking
            const Text(
              'Top Restaurants by Impact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...topRestaurants.map((r) => _buildRestaurantCard(r)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard(Map<String, dynamic> sentiment) {
    final thumbsUp = sentiment['thumbs_up'];
    final thumbsDown = sentiment['thumbs_down'];
    final positiveRatio = sentiment['positive_ratio'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Sentiment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSentimentItem(
                    '👍',
                    'Thumbs Up',
                    thumbsUp,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSentimentItem(
                    '👎',
                    'Thumbs Down',
                    thumbsDown,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: positiveRatio,
              backgroundColor: Colors.red.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${(positiveRatio * 100).toStringAsFixed(1)}% Positive',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentItem(
      String emoji, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final name = restaurant['name'];
    final avgRating = restaurant['avg_rating'];
    final reviewCount = restaurant['review_count'];
    final thumbsUp = restaurant['thumbs_up'];
    final thumbsDown = restaurant['thumbs_down'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  Icons.rate_review,
                  '$reviewCount reviews',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.thumb_up,
                  '$thumbsUp',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.thumb_down,
                  '$thumbsDown',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
