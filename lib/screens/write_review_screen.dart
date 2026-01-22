// lib/screens/write_review_screen.dart - LIGHTWEIGHT WITH COINS
import 'package:flutter/material.dart';
import '../services/review_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;

  const WriteReviewScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();

  double _overallRating = 5;
  double _foodQualityRating = 5;
  double _deliveryRating = 5;
  bool _isLoading = false;
  bool _isPositive = true; // Thumbs up/down

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final result = await _reviewService.checkEligibility(widget.orderId);

    if (!result['eligible']) {
      if (mounted) {
        _showMessage(result['message'], const Color(0xFFFF5252));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().length < 80) {
      _showMessage(
        'Please write at least 80 characters',
        const Color(0xFFFF9800),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _reviewService.submitReview(
      orderId: widget.orderId,
      rating: _overallRating,
      foodQualityRating: _foodQualityRating,
      deliveryRating: _deliveryRating,
      reviewText: _reviewController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showRewardDialog(result['data']);
    } else {
      _showMessage(result['message'], const Color(0xFFFF5252));
    }
  }

  void _showRewardDialog(Map<String, dynamic> data) {
    // Random coins between 1-100
    final coins = (data['review']['trust_score'] ?? 50) ~/ 2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Review Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Thank you for your honest feedback',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              // Coin Reward
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$coins Coins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '1 Coin = ₹1 • Use on your next order',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Write Review',
          style: TextStyle(
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF212121)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFF57C00),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Earn up to 100 coins! Write honest feedback.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Restaurant Name
            Text(
              widget.restaurantName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),

            const SizedBox(height: 20),

            // Thumbs Up/Down
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildThumbButton(
                    isPositive: true,
                    icon: Icons.thumb_up,
                    label: 'Good',
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThumbButton(
                    isPositive: false,
                    icon: Icons.thumb_down,
                    label: 'Bad',
                    color: const Color(0xFFFF5252),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Star Ratings
            _buildRatingRow('Overall Rating', _overallRating, (v) {
              setState(() => _overallRating = v);
            }),
            const SizedBox(height: 16),

            _buildRatingRow('Food Quality', _foodQualityRating, (v) {
              setState(() => _foodQualityRating = v);
            }),
            const SizedBox(height: 16),

            _buildRatingRow('Delivery', _deliveryRating, (v) {
              setState(() => _deliveryRating = v);
            }),

            const SizedBox(height: 24),

            // Review Text
            const Text(
              'Write Your Review',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _reviewController,
              maxLines: 6,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Share your experience... (min 80 characters)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 1.5,
                  ),
                ),
                counterText: '',
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  _reviewController.text.length >= 80
                      ? Icons.check_circle
                      : Icons.info,
                  size: 16,
                  color: _reviewController.text.length >= 80
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_reviewController.text.length} / 80 characters',
                  style: TextStyle(
                    fontSize: 12,
                    color: _reviewController.text.length >= 80
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _reviewController.text.trim().length >= 80 && !_isLoading
                        ? _submitReview
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbButton({
    required bool isPositive,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _isPositive == isPositive;

    return GestureDetector(
      onTap: () => setState(() => _isPositive = isPositive),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF616161),
            ),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onChanged((index + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  index < value ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFA000),
                  size: 28,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
