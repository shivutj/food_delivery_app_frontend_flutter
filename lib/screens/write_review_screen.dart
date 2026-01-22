// lib/screens/write_review_screen.dart - COMPLETE GENUINE REVIEW UI
import 'dart:ui';
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

class _WriteReviewScreenState extends State<WriteReviewScreen>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();

  // ✅ EMOJI SENTIMENT (thumbs up/down)
  String? _emojiSentiment; // thumbs_up or thumbs_down

  double _overallRating = 5;
  double _foodQualityRating = 5;
  double _deliveryRating = 5;
  bool _isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkEligibility();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkEligibility() async {
    final result = await _reviewService.checkEligibility(widget.orderId);

    if (!result['eligible']) {
      if (mounted) {
        _showMessage(result['message'], Colors.red);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitReview() async {
    // ✅ Validate emoji sentiment
    if (_emojiSentiment == null) {
      _showMessage('Please select thumbs up or thumbs down', Colors.orange);
      return;
    }

    if (_reviewController.text.trim().length < 80) {
      _showMessage('Review must be at least 80 characters', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _reviewService.submitReview(
      orderId: widget.orderId,
      emojiSentiment: _emojiSentiment!,
      rating: _overallRating,
      foodQualityRating: _foodQualityRating,
      deliveryRating: _deliveryRating,
      reviewText: _reviewController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showRewardDialog(result['data']);
    } else {
      _showMessage(result['message'], Colors.red);
    }
  }

  void _showRewardDialog(Map<String, dynamic> data) {
    final coinsRewarded = data['review']['coins_rewarded'] ?? 0;
    final trustScore = data['review']['trust_score'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ REWARD ANIMATION
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '🎉',
                          style: TextStyle(fontSize: 64 * value),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Review Submitted!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // ✅ COINS REWARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🪙',
                            style: TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: coinsRewarded),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) {
                              return Text(
                                '$value',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Coins',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Worth ₹$coinsRewarded',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trust Score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Trust Score: $trustScore/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildEmojiSentimentSelector(),
                      const SizedBox(height: 24),
                      _buildRatingSection(),
                      const SizedBox(height: 24),
                      _buildReviewTextField(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
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
              const Text(
                'Write Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.restaurantName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '✨ Your honest feedback helps improve service quality',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            '🎁 Earn 1-100 coins (₹1-₹100) for your review',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            '🔒 Your review appears anonymous to others',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiSentimentSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEmojiButton(
                  emoji: '👍',
                  label: 'Thumbs Up',
                  sentiment: 'thumbs_up',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEmojiButton(
                  emoji: '👎',
                  label: 'Thumbs Down',
                  sentiment: 'thumbs_down',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton({
    required String emoji,
    required String label,
    required String sentiment,
    required Color color,
  }) {
    final isSelected = _emojiSentiment == sentiment;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => setState(() => _emojiSentiment = sentiment),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [color.shade400, color.shade600],
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color.shade700 : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: isSelected ? 56 : 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Your Experience',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 24),
          _buildRatingRow(
            'Overall Rating',
            _overallRating,
            (value) => setState(() => _overallRating = value),
            Icons.star,
          ),
          const SizedBox(height: 20),
          _buildRatingRow(
            'Food Quality',
            _foodQualityRating,
            (value) => setState(() => _foodQualityRating = value),
            Icons.fastfood,
          ),
          const SizedBox(height: 20),
          _buildRatingRow(
            'Delivery Experience',
            _deliveryRating,
            (value) => setState(() => _deliveryRating = value),
            Icons.delivery_dining,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double value,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.orange.shade400),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade300,
                    Colors.orange.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onChanged((index + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  index < value ? Icons.star : Icons.star_border,
                  color: Colors.orange.shade400,
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReviewTextField() {
    final charCount = _reviewController.text.length;
    final isValid = charCount >= 80;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write Your Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 8,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Share your detailed experience... (minimum 80 characters)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.info,
                size: 16,
                color: isValid ? Colors.green : Colors.orange.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                '$charCount / 80 characters',
                style: TextStyle(
                  fontSize: 13,
                  color: isValid ? Colors.green : Colors.orange.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _emojiSentiment != null && _reviewController.text.trim().length >= 80;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: canSubmit
            ? LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade300,
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit && !_isLoading ? _submitReview : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
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
                    'Submit Review & Earn Coins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
