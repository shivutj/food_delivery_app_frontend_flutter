// lib/models/restaurant.dart - FIXED
class Restaurant {
  final String id;
  final String name;
  final String image; // ✅ Keep old field for backward compatibility
  final List<String> images; // ✅ New field
  final String? video;
  final double rating;
  final Location? location; // ✅ Changed from RestaurantLocation
  final String? description;
  final String? phone;
  final String? cuisine;

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.images,
    this.video,
    required this.rating,
    this.location,
    this.description,
    this.phone,
    this.cuisine,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // ✅ Handle both old and new image formats
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }
    
    // ✅ Fallback to old single image field
    String singleImage = json['image'] ?? 'https://via.placeholder.com/400x300?text=No+Image';
    if (imagesList.isEmpty && singleImage.isNotEmpty) {
      imagesList = [singleImage];
    }

    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: singleImage, // ✅ Keep for backward compatibility
      images: imagesList,
      video: json['video'],
      rating: (json['rating'] ?? 0).toDouble(),
      location: json['location'] != null 
          ? Location.fromJson(json['location']) 
          : null,
      description: json['description'],
      phone: json['phone'],
      cuisine: json['cuisine'],
    );
  }

  // ✅ Helper: Get primary image
  String get primaryImage {
    if (images.isNotEmpty) return images.first;
    if (image.isNotEmpty) return image;
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }
}

// ✅ Renamed from RestaurantLocation to Location
class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
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