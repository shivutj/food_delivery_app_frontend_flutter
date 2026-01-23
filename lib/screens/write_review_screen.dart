// lib/screens/write_review_screen.dart - FIXED CHARACTER COUNT & SUBMIT
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
    final text = _reviewController.text.trim();

    if (text.length < 80) {
      _showMessage(
        'Please write at least 80 characters (${80 - text.length} more needed)',
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
        reviewText: text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success']) {
        _showRewardDialog(result['data']);
      } else {
        _showMessage(
          result['message'] ?? 'Failed to submit review',
          const Color(0xFFFF5252),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Error: ${e.toString()}', const Color(0xFFFF5252));
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
                'Thank you for your honest feedback',
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Write Review',
          style: TextStyle(color: Color(0xFF212121)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF212121)),
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
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            _buildRatingRow('Overall Rating', _overallRating,
                (v) => setState(() => _overallRating = v)),
            _buildRatingRow('Food Quality', _foodQualityRating,
                (v) => setState(() => _foodQualityRating = v)),
            _buildRatingRow('Delivery', _deliveryRating,
                (v) => setState(() => _deliveryRating = v)),
            const SizedBox(height: 24),
            Text(
              'Write your review',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 6,
              maxLength: 2000,
              onChanged: (text) {
                setState(() {
                  _charCount = text.trim().length;
                });
              },
              decoration: InputDecoration(
                hintText:
                    'Share your experience... (minimum 80 characters required)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                  borderSide:
                      const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _charCount >= 80
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _charCount >= 80
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _charCount >= 80
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 16,
                        color: _charCount >= 80
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_charCount / 80 characters',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _charCount >= 80
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_charCount < 80) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${80 - _charCount} more needed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _charCount >= 80 && !_isLoading ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: _charCount >= 80 ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : Text(
                        _charCount >= 80
                            ? 'Submit Review'
                            : 'Write at least 80 characters',
                        style: TextStyle(
                          color: _charCount >= 80
                              ? Colors.white
                              : Colors.grey.shade600,
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
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => onChanged((i + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < value ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFA000),
                    size: 28,
                  ),
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
