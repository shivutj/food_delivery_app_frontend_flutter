// lib/models/menu_item.dart - WITH VEG/NON-VEG SUPPORT
class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final int price; // ✅ INTEGER ONLY (no decimals)
  final String image;
  final String category;
  final String? description;
  final bool available;
  final bool isVeg; // ✅ NEW: Veg/Non-Veg flag
  final String? video; // ✅ NEW: Video URL

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.description,
    this.available = true,
    this.isVeg = true, // Default to Veg
    this.video,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toInt(), // ✅ Ensure integer
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      available: json['available'] ?? true,
      isVeg: json['isVeg'] ?? true, // ✅ NEW
      video: json['video'], // ✅ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'description': description,
      'available': available,
      'isVeg': isVeg, // ✅ NEW
      'video': video, // ✅ NEW
    };
  }
}