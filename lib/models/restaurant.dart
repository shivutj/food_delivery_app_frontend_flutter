// lib/models/restaurant.dart - UPDATED WITH MEDIA & LOCATION
class Restaurant {
  final String id;
  final String name;
  final List<String> images; // ✅ Multiple images
  final String? video; // ✅ Video URL
  final double rating;
  final RestaurantLocation location; // ✅ Required location
  final String? description;
  final String? phone;
  final String? cuisine;

  Restaurant({
    required this.id,
    required this.name,
    required this.images,
    this.video,
    required this.rating,
    required this.location,
    this.description,
    this.phone,
    this.cuisine,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      video: json['video'],
      rating: (json['rating'] ?? 0).toDouble(),
      location: RestaurantLocation.fromJson(json['location'] ?? {}),
      description: json['description'],
      phone: json['phone'],
      cuisine: json['cuisine'],
    );
  }

  // ✅ Fallback: Return first image or placeholder
  String get primaryImage {
    if (images.isNotEmpty) return images.first;
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }
}

class RestaurantLocation {
  final double latitude;
  final double longitude;
  final String address;

  RestaurantLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) {
    return RestaurantLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}