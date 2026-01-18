// lib/screens/food_detail_screen.dart - WITH VIDEO & DEMO AI
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';

class FoodDetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  const FoodDetailScreen({super.key, required this.menuItem});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.menuItem.video != null && widget.menuItem.video!.isNotEmpty) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.menuItem.video!),
    );
    await _videoController!.initialize();
    setState(() {});
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  // ✅ DEMO AI Feature (Rule-based, no real AI)
  void _showAIDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Ask about this food'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask me anything about "${widget.menuItem.name}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAIQuestion('Is this spicy?'),
            _buildAIQuestion('I have peanut allergy, is this safe?'),
            _buildAIQuestion('What are the ingredients?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAIQuestion(String question) {
    return ListTile(
      leading: const Icon(Icons.question_answer, size: 20),
      title: Text(question, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        _showAIResponse(question);
      },
    );
  }

  void _showAIResponse(String question) {
    String response = '';
    
    // ✅ Simple rule-based responses (DEMO ONLY)
    if (question.toLowerCase().contains('spicy')) {
      response = widget.menuItem.description?.toLowerCase().contains('spicy') ?? false
          ? 'Yes, this dish is spicy. 🌶️'
          : 'This dish has a mild flavor, not very spicy. 😊';
    } else if (question.toLowerCase().contains('allergy') || question.toLowerCase().contains('peanut')) {
      response = 'This dish may contain traces of nuts. Please consult the restaurant directly for detailed allergen information. ⚠️';
    } else if (question.toLowerCase().contains('ingredient')) {
      response = 'Ingredients: ${widget.menuItem.description ?? "Please check with the restaurant for detailed ingredients."}';
    } else {
      response = 'I don\'t have specific information about that. Please contact the restaurant directly. 📞';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('AI Response'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Q: $question',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(response),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This is a demo AI response',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image/Video Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (_videoController == null || !_videoController!.value.isInitialized)
                    CachedNetworkImage(
                      imageUrl: widget.menuItem.image,
                      fit: BoxFit.cover,
                    ),
                  
                  // Video
                  if (_videoController != null && _videoController!.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  
                  // Video Play Button
                  if (_videoController != null && _videoController!.value.isInitialized)
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                          onPressed: _toggleVideo,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/Non-Veg Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.menuItem.isVeg
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      border: Border.all(
                        color: widget.menuItem.isVeg
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.menuItem.isVeg ? '🟢 Pure Veg' : '🔴 Non-Veg',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.menuItem.isVeg
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    widget.menuItem.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category
                  Text(
                    widget.menuItem.category,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '₹${widget.menuItem.price}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (widget.menuItem.description != null) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.menuItem.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ✅ Demo AI Button
                  OutlinedButton.icon(
                    onPressed: _showAIDialog,
                    icon: Icon(Icons.psychology, color: Colors.blue.shade600),
                    label: const Text('Ask AI about this food'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Add to Cart Button (Fixed at bottom)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: widget.menuItem.available
                ? () {
                    Provider.of<CartProvider>(context, listen: false)
                        .addItem(widget.menuItem);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.menuItem.name} added to cart'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.menuItem.available
                  ? 'Add to Cart - ₹${widget.menuItem.price}'
                  : 'Currently Unavailable',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}