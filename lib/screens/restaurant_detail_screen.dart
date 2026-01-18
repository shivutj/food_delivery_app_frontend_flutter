// lib/screens/restaurant_detail_screen.dart - NEW FILE (Customer View)
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/restaurant.dart';
import 'menu_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final PageController _pageController = PageController();
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.restaurant.video != null && widget.restaurant.video!.isNotEmpty) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.restaurant.video!),
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

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.restaurant.images.isNotEmpty;
    final hasVideo = widget.restaurant.video != null && widget.restaurant.video!.isNotEmpty;
    final hasMedia = hasImages || hasVideo;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ✅ MEDIA GALLERY (Images + Video)
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasMedia
                  ? Stack(
                      children: [
                        // Image/Video Carousel
                        PageView(
                          controller: _pageController,
                          children: [
                            // Images
                            if (hasImages)
                              ...widget.restaurant.images.map((imageUrl) {
                                return CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.restaurant, size: 64),
                                  ),
                                );
                              }),
                            // Video
                            if (hasVideo && _videoController != null && _videoController!.value.isInitialized)
                              Stack(
                                fit: StackFit.expand,
                                children: [
                                  VideoPlayer(_videoController!),
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
                          ],
                        ),
                        // Page Indicator
                        if ((hasImages ? widget.restaurant.images.length : 0) + (hasVideo ? 1 : 0) > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: (hasImages ? widget.restaurant.images.length : 0) + (hasVideo ? 1 : 0),
                                effect: WormEffect(
                                  dotWidth: 8,
                                  dotHeight: 8,
                                  activeDotColor: Colors.white,
                                  dotColor: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                    ),
            ),
          ),

          // ✅ RESTAURANT INFO
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
                  // Name & Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.restaurant.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade700, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            widget.restaurant.rating.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description (if available)
                  if (widget.restaurant.description?.isNotEmpty ?? false) ...[
                    Text(
                      widget.restaurant.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Cuisine (if available)
                  if (widget.restaurant.cuisine?.isNotEmpty ?? false) ...[
                    Row(
                      children: [
                        Icon(Icons.fastfood, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.restaurant.cuisine!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Phone (if available)
                  if (widget.restaurant.phone?.isNotEmpty ?? false) ...[
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.restaurant.phone!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.restaurant.location.address,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // View Menu Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuScreen(restaurant: widget.restaurant),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}