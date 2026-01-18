// lib/providers/cart_provider.dart - PERSISTENT CART WITH STORAGE
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  // ✅ Load cart from storage
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

  // ✅ Save cart to storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('cart', jsonEncode(cartData));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // ✅ Add item with persistence
  Future<void> addItem(MenuItem menuItem) async {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
    await _saveCart();
  }

  // ✅ Remove item with persistence
  Future<void> removeItem(String menuItemId) async {
    _items.remove(menuItemId);
    notifyListeners();
    await _saveCart();
  }

  // ✅ Update quantity with persistence
  Future<void> updateQuantity(String menuItemId, int quantity) async {
    if (_items.containsKey(menuItemId)) {
      if (quantity > 0) {
        _items[menuItemId]!.quantity = quantity;
      } else {
        _items.remove(menuItemId);
      }
      notifyListeners();
      await _saveCart();
    }
  }

  // ✅ Clear cart (only after successful order)
  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveCart();
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
}