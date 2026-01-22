// lib/screens/restaurant_reviews_enhanced.dart - GLASSMORPHISM REVIEWS
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../models/restaurant.dart';

class RestaurantReviewsEnhanced extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantReviewsEnhanced({super.key, required this.restaurant});

  @override
  State<RestaurantReviewsEnhanced> createState() =>
      _RestaurantReviewsEnhancedState();
}

class _RestaurantReviewsEnhancedState extends State<RestaurantReviewsEnhanced> {
  final ReviewService _reviewService = ReviewService();

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    final reviews = await _reviewService.getRestaurantReviews(
      widget.restaurant.id,
      sort: _sortBy,
    );

    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  Future<void> _markHelpful(String reviewId, bool isHelpful) async {
    final success = await _reviewService.markHelpful(reviewId, isHelpful);

    if (success) {
      _showMessage('Feedback recorded', Colors.green);
      _loadReviews();
    } else {
      _showMessage('Failed to record feedback', Colors.red);
    }
  }

  void _showReportDialog(String reviewId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Report Review',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Why are you reporting this review?',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.length >= 10) {
                            Navigator.pop(context);
                            final success = await _reviewService.reportReview(
                              reviewId,
                              reason,
                            );
                            if (success) {
                              _showMessage('Review reported', Colors.green);
                            }
                          } else {
                            _showMessage(
                              'Reason must be at least 10 characters',
                              Colors.orange,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Report',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.orange.shade50,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGlassAppBar(),
              _buildSortBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              return _buildReviewCard(_reviews[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    Text(
                      '${_reviews.length} verified reviews',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSortChip('Recent', 'recent'),
            const SizedBox(width: 8),
            _buildSortChip('Most Helpful', 'helpful'),
            const SizedBox(width: 8),
            _buildSortChip('Highest Rated', 'rating_high'),
            const SizedBox(width: 8),
            _buildSortChip('Lowest Rated', 'rating_low'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        _loadReviews();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.orange.shade300,
                    Colors.orange.shade200,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: isSelected ? 10 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user_id'];
    final rating = review['rating'].toDouble();
    final trustScore = review['trust_score'];
    final labels = List<String>.from(review['labels'] ?? []);
    final reviewerLevel = review['reviewer_level'] ?? 'bronze';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildReviewerBadge(reviewerLevel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.orange.shade400,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: trustScore >= 70
                        ? [Colors.green.shade300, Colors.green.shade100]
                        : trustScore >= 40
                            ? [Colors.orange.shade300, Colors.orange.shade100]
                            : [Colors.red.shade300, Colors.red.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Trust: $trustScore',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Labels
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: labels.map((label) => _buildLabel(label)).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Review Text
          Text(
            review['review_text'],
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          // Helpful Buttons
          Row(
            children: [
              _buildHelpfulButton(
                review['_id'],
                true,
                review['helpful_count'],
              ),
              const SizedBox(width: 12),
              _buildHelpfulButton(
                review['_id'],
                false,
                review['not_helpful_count'],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.flag_outlined, color: Colors.grey.shade400),
                onPressed: () => _showReportDialog(review['_id']),
              ),
            ],
          ),

          // Restaurant Response
          if (review['restaurant_response'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store,
                          size: 16, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Restaurant Response',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['restaurant_response']['text'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewerBadge(String level) {
    Color color;
    String label;

    switch (level) {
      case 'elite':
        color = Colors.purple;
        label = 'Elite';
        break;
      case 'platinum':
        color = Colors.blue;
        label = 'Platinum';
        break;
      case 'gold':
        color = Colors.amber;
        label = 'Gold';
        break;
      case 'silver':
        color = Colors.grey;
        label = 'Silver';
        break;
      default:
        color = Colors.brown;
        label = 'Bronze';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    IconData icon;
    Color color;
    String text;

    switch (label) {
      case 'verified_order':
        icon = Icons.verified;
        color = Colors.green;
        text = 'Verified';
        break;
      case 'frequent_customer':
        icon = Icons.star;
        color = Colors.amber;
        text = 'Frequent';
        break;
      case 'trusted_reviewer':
        icon = Icons.shield;
        color = Colors.blue;
        text = 'Trusted';
        break;
      case 'first_review':
        icon = Icons.new_releases;
        color = Colors.purple;
        text = 'First Review';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        text = label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulButton(String reviewId, bool isHelpful, int count) {
    return GestureDetector(
      onTap: () => _markHelpful(reviewId, isHelpful),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHelpful ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review!',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
