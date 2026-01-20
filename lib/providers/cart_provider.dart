// lib/providers/cart_provider.dart - FIXED EMPTY CART ON LOGIN
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

  // ✅ FIX: Load cart ONLY if data exists and is valid
  Future<void> loadCart() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');
      
      // ✅ Clear items first
      _items.clear();
      
      // ✅ Only load if cart data exists
      if (cartJson != null && cartJson.isNotEmpty && cartJson != '{}') {
        try {
          final Map<String, dynamic> cartData = jsonDecode(cartJson);
          
          // ✅ Only add items if cartData is not empty
          if (cartData.isNotEmpty) {
            cartData.forEach((key, value) {
              try {
                _items[key] = CartItem.fromJson(value);
              } catch (e) {
                print('⚠️ Error loading cart item $key: $e');
              }
            });
          }
        } catch (e) {
          print('⚠️ Error parsing cart data: $e');
          // Clear corrupted cart data
          await prefs.remove('cart');
        }
      }
      
      _isLoaded = true;
      print('✅ Cart loaded: ${_items.length} items');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading cart: $e');
      _items.clear();
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDuration, _saveCart);
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_items.isEmpty) {
        // ✅ Remove cart data if empty
        await prefs.remove('cart');
        print('✅ Cart cleared from storage');
      } else {
        final cartData = _items.map((key, value) => MapEntry(key, value.toJson()));
        await prefs.setString('cart', jsonEncode(cartData));
        print('✅ Cart saved: ${_items.length} items');
      }
    } catch (e) {
      print('❌ Error saving cart: $e');
    }
  }

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
    _debouncedSave();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
    _debouncedSave();
  }

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

  // ✅ FIX: Clear cart properly with immediate save
  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveCart();
    print('🗑️ Cart cleared completely');
  }

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