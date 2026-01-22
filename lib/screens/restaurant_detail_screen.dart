// lib/screens/restaurant_detail_screen.dart - FIXED REVIEWS ROUTING
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant.dart';
import 'menu_screen.dart';
import 'table_booking_screen.dart';
import 'restaurant_reviews_enhanced.dart'; // ✅ FIXED: Using enhanced reviews
import 'restaurant_offers_screen.dart';

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
    if (widget.restaurant.video != null &&
        widget.restaurant.video!.isNotEmpty) {
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

  Future<void> _openDirections() async {
    if (!widget.restaurant.hasLocation) {
      _showMessage('Location not available for this restaurant', Colors.red);
      return;
    }

    final lat = widget.restaurant.location!.latitude;
    final lng = widget.restaurant.location!.longitude;

    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Could not open maps', Colors.red);
      }
    } catch (e) {
      _showMessage('Error opening maps: $e', Colors.red);
    }
  }

  Future<void> _callRestaurant() async {
    final phone = widget.restaurant.bookingPhone ?? widget.restaurant.phone;

    if (phone == null || phone.isEmpty) {
      _showMessage('Phone number not available', Colors.red);
      return;
    }

    final url = Uri.parse('tel:$phone');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showMessage('Could not make call', Colors.red);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.restaurant.images.isNotEmpty;
    final hasVideo =
        widget.restaurant.video != null && widget.restaurant.video!.isNotEmpty;
    final hasMedia = hasImages || hasVideo;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // MEDIA GALLERY
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasMedia
                  ? Stack(
                      children: [
                        PageView(
                          controller: _pageController,
                          children: [
                            if (hasImages)
                              ...widget.restaurant.images.map(
                                (imageUrl) => CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child:
                                        const Icon(Icons.restaurant, size: 64),
                                  ),
                                ),
                              ),
                            if (hasVideo &&
                                _videoController != null &&
                                _videoController!.value.isInitialized)
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
                                          _isVideoPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
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
                        if ((hasImages ? widget.restaurant.images.length : 0) +
                                (hasVideo ? 1 : 0) >
                            1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: (hasImages
                                        ? widget.restaurant.images.length
                                        : 0) +
                                    (hasVideo ? 1 : 0),
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
                      child: const Icon(Icons.restaurant,
                          size: 100, color: Colors.grey),
                    ),
            ),
          ),

          // RESTAURANT INFO
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.amber.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              widget.restaurant.rating.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dine-In Badge
                  if (widget.restaurant.dineInAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Dine-In Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildQuickAction(
                        icon: Icons.call,
                        label: 'Call',
                        color: Colors.blue,
                        onTap: _callRestaurant,
                      ),
                      _buildQuickAction(
                        icon: Icons.directions,
                        label: 'Directions',
                        color: Colors.green,
                        onTap: widget.restaurant.hasLocation
                            ? _openDirections
                            : null,
                      ),
                      _buildQuickAction(
                        icon: Icons.local_offer,
                        label: 'Offers',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantOffersScreen(
                                restaurant: widget.restaurant,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.star_rate,
                        label: 'Reviews',
                        color: Colors.amber,
                        onTap: () {
                          // ✅ FIXED: Navigate to enhanced reviews screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantReviewsEnhanced(
                                restaurant: widget.restaurant,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (widget.restaurant.description?.isNotEmpty ?? false) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.restaurant.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Info Cards
                  if (widget.restaurant.operatingHours != null)
                    _buildInfoCard(
                      Icons.access_time,
                      'Operating Hours',
                      widget.restaurant.operatingHours!,
                      Colors.blue,
                    ),
                  if (widget.restaurant.cuisine?.isNotEmpty ?? false)
                    _buildInfoCard(
                      Icons.fastfood,
                      'Cuisine',
                      widget.restaurant.cuisine!,
                      Colors.green,
                    ),
                  if (widget.restaurant.location != null)
                    _buildInfoCard(
                      Icons.location_on,
                      'Location',
                      widget.restaurant.location!.address,
                      Colors.red,
                    ),
                  const SizedBox(height: 24),

                  // Main Action Buttons
                  if (widget.restaurant.dineInAvailable)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TableBookingScreen(
                                restaurant: widget.restaurant,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_seat, color: Colors.white),
                        label: const Text(
                          'Book a Table',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (widget.restaurant.dineInAvailable)
                    const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MenuScreen(restaurant: widget.restaurant),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu,
                          color: Colors.white),
                      label: const Text(
                        'View Menu & Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade300 : color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? Colors.grey.shade400 : color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey.shade400 : color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
