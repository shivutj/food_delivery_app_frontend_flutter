// lib/screens/restaurant_reviews_screen.dart - DEMO REVIEWS
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/restaurant.dart';

class RestaurantReviewsScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantReviewsScreen({super.key, required this.restaurant});

  // Demo reviews
  List<Map<String, dynamic>> get _reviews => [
    {
      'name': 'Priya Sharma',
      'rating': 5.0,
      'date': '2 days ago',
      'comment': 'Excellent food quality and amazing ambiance! The dine-in experience was fantastic. Highly recommended for family gatherings.',
      'helpful': 24,
      'avatar': '👩',
    },
    {
      'name': 'Rahul Kumar',
      'rating': 4.5,
      'date': '1 week ago',
      'comment': 'Great taste and quick service. The delivery was on time and food was hot. Will definitely order again!',
      'helpful': 18,
      'avatar': '👨',
    },
    {
      'name': 'Anita Desai',
      'rating': 5.0,
      'date': '2 weeks ago',
      'comment': 'Best restaurant in the area! Staff is very courteous and the menu variety is impressive. Must try their special dishes.',
      'helpful': 31,
      'avatar': '👩‍🦰',
    },
    {
      'name': 'Vikram Singh',
      'rating': 4.0,
      'date': '3 weeks ago',
      'comment': 'Good food but slightly expensive. Portion sizes are decent. The ambiance makes up for the price though.',
      'helpful': 12,
      'avatar': '👨‍🦱',
    },
    {
      'name': 'Sneha Patel',
      'rating': 5.0,
      'date': '1 month ago',
      'comment': 'Absolutely loved everything! From booking to service to food quality. Perfect spot for date nights. Will come again for sure!',
      'helpful': 42,
      'avatar': '👩‍🦳',
    },
  ];

  Map<String, int> get _ratingDistribution => {
    '5': 156,
    '4': 89,
    '3': 23,
    '2': 8,
    '1': 4,
  };

  @override
  Widget build(BuildContext context) {
    final totalReviews = _ratingDistribution.values.reduce((a, b) => a + b);
    final avgRating = restaurant.rating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        backgroundColor: Colors.amber.shade600,
      ),
      body: Column(
        children: [
          // Rating Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade400],
              ),
            ),
            child: Column(
              children: [
                Text(
                  avgRating.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RatingBarIndicator(
                  rating: avgRating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.white,
                  ),
                  itemCount: 5,
                  itemSize: 28.0,
                ),
                const SizedBox(height: 12),
                Text(
                  '$totalReviews Reviews',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Rating Distribution
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._ratingDistribution.entries.map((entry) {
                  final stars = entry.key;
                  final count = entry.value;
                  final percentage = (count / totalReviews * 100).toInt();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$stars ⭐',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _buildReviewCard(review);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteReviewDialog(context),
        backgroundColor: Colors.amber.shade600,
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text(
          'Write Review',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      review['avatar'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: review['rating'],
                            itemBuilder: (context, index) => Icon(
                              Icons.star,
                              color: Colors.amber.shade600,
                            ),
                            itemCount: 5,
                            itemSize: 16.0,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['comment'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Helpful (${review['helpful']})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Write a Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rate your experience'),
                const SizedBox(height: 12),
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 40,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                  ),
                  onRatingUpdate: (value) {
                    setState(() => rating = value);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review submitted successfully! 🎉'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}