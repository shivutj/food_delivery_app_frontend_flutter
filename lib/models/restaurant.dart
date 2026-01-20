// lib/models/restaurant.dart - WITH DINE-IN SUPPORT
class Restaurant {
  final String id;
  final String name;
  final String image;
  final List<String> images;
  final String? video;
  final double rating;
  final Location? location;
  final String? description;
  final String? phone;
  final String? cuisine;
  final bool dineInAvailable;      // ✅ NEW
  final String? operatingHours;    // ✅ NEW
  final String? bookingPhone;      // ✅ NEW

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
    this.dineInAvailable = true,  // ✅ Default to true
    this.operatingHours,
    this.bookingPhone,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }
    
    String singleImage = json['image'] ?? 'https://via.placeholder.com/400x300?text=No+Image';
    if (imagesList.isEmpty && singleImage.isNotEmpty) {
      imagesList = [singleImage];
    }

    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: singleImage,
      images: imagesList,
      video: json['video'],
      rating: (json['rating'] ?? 0).toDouble(),
      location: json['location'] != null 
          ? Location.fromJson(json['location']) 
          : null,
      description: json['description'],
      phone: json['phone'],
      cuisine: json['cuisine'],
      dineInAvailable: json['dineInAvailable'] ?? true,  // ✅ NEW
      operatingHours: json['operatingHours'],            // ✅ NEW
      bookingPhone: json['bookingPhone'],                // ✅ NEW
    );
  }

  String get primaryImage {
    if (images.isNotEmpty) return images.first;
    if (image.isNotEmpty) return image;
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }

  // ✅ NEW: Check if location is available for directions
  bool get hasLocation {
    return location != null && 
           location!.latitude != 0 && 
           location!.longitude != 0;
  }
}

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