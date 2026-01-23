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
  bool _isPositive = true;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final result = await _reviewService.checkEligibility(widget.orderId);
    if (!result['eligible'] && mounted) {
      _showMessage(result['message'], const Color(0xFFFF5252));
      Navigator.pop(context);
    }
  }

  Future<void> _submitReview() async {
    final textLength = _reviewController.text.trim().length;

    // ✅ FIX: Removed the 80-char minimum. Now just checks if empty.
    if (textLength == 0) {
      _showMessage(
        'Please write something about your experience.',
        const Color(0xFFFF9800),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _reviewService.submitReview(
        orderId: widget.orderId,
        emojiSentiment: _isPositive ? 'thumbs_up' : 'thumbs_down',
        rating: _overallRating,
        foodQualityRating: _foodQualityRating,
        deliveryRating: _deliveryRating,
        reviewText: _reviewController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (result['success']) {
        if (mounted) {
          _showRewardDialog(result['data']);
        }
      } else {
        if (mounted) {
          _showMessage(result['message'], const Color(0xFFFF5252));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Error: ${e.toString()}', const Color(0xFFFF5252));
      }
    }
  }

  void _showRewardDialog(Map<String, dynamic> data) {
    final coins = data['review']?['coins_rewarded'] ?? 50;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your feedback',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
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
                    const Icon(Icons.monetization_on,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
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
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Write Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurantName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('How was your experience?'),
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
            _buildRatingRow('Overall Rating', _overallRating,
                (v) => setState(() => _overallRating = v)),
            _buildRatingRow('Food Quality', _foodQualityRating,
                (v) => setState(() => _foodQualityRating = v)),
            _buildRatingRow('Delivery', _deliveryRating,
                (v) => setState(() => _deliveryRating = v)),
            const SizedBox(height: 24),

            // ✅ UPDATED TEXT FIELD
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 80, // ✅ Strictly limits input to 80 chars
              onChanged: (text) {
                setState(() {
                  _charCount = text.trim().length;
                });
              },
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                border: const OutlineInputBorder(),
                // ✅ Simplified counter
                counterText: '$_charCount/80',
                counterStyle: TextStyle(
                  color: _charCount == 80 ? Colors.red : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
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
                          fontWeight: FontWeight.bold,
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
    final selected = _isPositive == isPositive;
    return GestureDetector(
      onTap: () => setState(() => _isPositive = isPositive),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => onChanged((i + 1).toDouble()),
                child: Icon(
                  i < value ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFA000),
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
