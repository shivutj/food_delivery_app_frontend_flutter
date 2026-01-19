// lib/providers/cart_provider.dart - OPTIMIZED VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'menuItem': {
        'id': menuItem.id,
        'restaurantId': menuItem.restaurantId,
        'name': menuItem.name,
        'price': menuItem.price,
        'image': menuItem.image,
        'category': menuItem.category,
        'description': menuItem.description,
        'available': menuItem.available,
      },
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  bool _isLoaded = false;
  Timer? _saveTimer;

  // Debounce duration for saving
  static const Duration _saveDuration = Duration(milliseconds: 500);

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;

  int get totalItemCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.menuItem.price * cartItem.quantity;
    });
    return total;
  }

  // Load cart from storage (optimized - only once)
  Future<void> loadCart() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');
      
      if (cartJson != null) {
        final Map<String, dynamic> cartData = jsonDecode(cartJson);
        _items.clear();
        
        cartData.forEach((key, value) {
          _items[key] = CartItem.fromJson(value);
        });
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Debounced save to prevent excessive writes
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDuration, _saveCart);
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('cart', jsonEncode(cartData));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Optimized add item - immediate UI update, debounced save
  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
    _debouncedSave();
  }

  // Optimized remove item
  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
    _debouncedSave();
  }

  // Optimized update quantity
  void updateQuantity(String menuItemId, int quantity) {
    if (_items.containsKey(menuItemId)) {
      if (quantity > 0) {
        _items[menuItemId]!.quantity = quantity;
      } else {
        _items.remove(menuItemId);
      }
      notifyListeners();
      _debouncedSave();
    }
  }

  // Clear cart (immediate save)
  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveCart(); // Immediate save for critical action
  }

  // Get order items in API format
  List<Map<String, dynamic>> getOrderItems() {
    return _items.values.map((cartItem) {
      return {
        'menu_id': cartItem.menuItem.id,
        'name': cartItem.menuItem.name,
        'price': cartItem.menuItem.price,
        'quantity': cartItem.quantity,
      };
    }).toList();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}