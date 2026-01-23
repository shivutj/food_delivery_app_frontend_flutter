// lib/screens/write_review_screen.dart - FIXED CHARACTER VALIDATION
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
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
    
    // ✅ Listen to text changes
    _reviewController.addListener(() {
      setState(() {
        _currentLength = _reviewController.text.trim().length;
      });
    });
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
    final reviewText = _reviewController.text.trim();
    
    // ✅ FIXED: Allow any text length (removed 80 char minimum)
    if (reviewText.isEmpty) {
      _showMessage('Please write something about your experience', const Color(0xFFFF9800));
      return;
    }

    // ✅ Optional: Recommend longer reviews but don't enforce
    if (reviewText.length < 20) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Short Review'),
          content: const Text(
            'Your review is quite short. A more detailed review helps other customers and earns you more coins. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Writing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    final result = await _reviewService.submitReview(
      orderId: widget.orderId,
      emojiSentiment: _isPositive ? 'thumbs_up' : 'thumbs_down',
      rating: _overallRating,
      foodQualityRating: _foodQualityRating,
      deliveryRating: _deliveryRating,
      reviewText: reviewText,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showRewardDialog(result['data']);
    } else {
      _showMessage(result['message'], const Color(0xFFFF5252));
    }
  }

  void _showRewardDialog(Map<String, dynamic> data) {
    final coins = data['review']?['coins_rewarded'] ?? 50;
    final trustScore = data['review']?['trust_score'] ?? 50;

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
              
              // Coins Earned
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
              
              const SizedBox(height: 16),
              
              // Trust Score
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Trust Score: $trustScore',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
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
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return to orders
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    // ✅ Button enabled if text is not empty
    final canSubmit = _currentLength > 0 && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Write Review'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.amber.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.restaurantName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sentiment Selection
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

            // Ratings
            _buildRatingRow('Overall Rating', _overallRating,
                (v) => setState(() => _overallRating = v)),
            const SizedBox(height: 12),
            _buildRatingRow('Food Quality', _foodQualityRating,
                (v) => setState(() => _foodQualityRating = v)),
            const SizedBox(height: 12),
            _buildRatingRow('Delivery', _deliveryRating,
                (v) => setState(() => _deliveryRating = v)),
            const SizedBox(height: 24),

            // Review Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your Review',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // ✅ Character counter
                    Text(
                      '$_currentLength / 2000',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentLength < 20 
                            ? Colors.orange.shade700 
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ✅ Helpful hint
                if (_currentLength < 20)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Detailed reviews earn more coins! (recommended: 20+ characters)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _reviewController,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ✅ Submit Button - Always visible, enabled based on text
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange.shade600,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : Text(
                        canSubmit ? 'Submit Review' : 'Write your review first',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: canSubmit ? Colors.white : Colors.grey.shade600,
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
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey.shade600,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
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