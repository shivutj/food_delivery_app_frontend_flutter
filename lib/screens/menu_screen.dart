// lib/screens/menu_screen.dart - WITH VEG/NON-VEG FILTER & GRADIENTS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final Restaurant restaurant;

  const MenuScreen({super.key, required this.restaurant});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // All, Veg, NonVeg
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final menu = await _apiService.getMenu(widget.restaurant.id);
    setState(() {
      _menuItems = menu;
      _applyFilter();
      _isLoading = false;
    });
    _animationController.forward();
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredItems = _menuItems;
      } else if (_selectedFilter == 'Veg') {
        _filteredItems = _menuItems.where((item) => item.isVeg).toList();
      } else {
        _filteredItems = _menuItems.where((item) => !item.isVeg).toList();
      }
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
    _animationController.reset();
    _animationController.forward();
  }

  // ✅ Dynamic gradient based on filter
  LinearGradient _getBackgroundGradient() {
    if (_selectedFilter == 'NonVeg') {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.red.shade50,
          Colors.orange.shade50,
          Colors.white,
        ],
      );
    } else if (_selectedFilter == 'Veg') {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.shade50,
          Colors.teal.shade50,
          Colors.white,
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF8E1), // Warm cream
          Color(0xFFFFE0B2), // Light orange
          Colors.white,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: _selectedFilter == 'NonVeg'
                  ? Colors.red.shade700
                  : _selectedFilter == 'Veg'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.restaurant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _selectedFilter == 'NonVeg'
                          ? [Colors.red.shade800, Colors.red.shade600]
                          : _selectedFilter == 'Veg'
                              ? [Colors.green.shade800, Colors.green.shade600]
                              : [Colors.orange.shade800, Colors.orange.shade600],
                    ),
                  ),
                ),
              ),
              actions: [
                Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          },
                        ),
                        if (cart.totalItemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '${cart.totalItemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip('All', Icons.restaurant_menu, Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterChip('Veg', Icons.eco, Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterChip('NonVeg', Icons.set_meal, Colors.red),
                    ),
                  ],
                ),
              ),
            ),

            // Count Badge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fastfood,
                        color: _selectedFilter == 'NonVeg'
                            ? Colors.red.shade700
                            : _selectedFilter == 'Veg'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_filteredItems.length} ${_selectedFilter == 'All' ? 'Items' : _selectedFilter == 'Veg' ? 'Veg Items' : 'Non-Veg Items'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Menu Items
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _filteredItems.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _filteredItems[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildMenuItem(item),
                              );
                            },
                            childCount: _filteredItems.length,
                          ),
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color) {
    final isSelected = _selectedFilter == label;
    
    // ✅ Define gradient colors based on the base color
    Color darkColor;
    Color lightColor;
    Color borderColor;
    Color textColor;
    
    if (label == 'Veg') {
      darkColor = Colors.green.shade600;
      lightColor = Colors.green.shade400;
      borderColor = Colors.green.shade700;
      textColor = Colors.green.shade700;
    } else if (label == 'NonVeg') {
      darkColor = Colors.red.shade600;
      lightColor = Colors.red.shade400;
      borderColor = Colors.red.shade700;
      textColor = Colors.red.shade700;
    } else {
      darkColor = Colors.orange.shade600;
      lightColor = Colors.orange.shade400;
      borderColor = Colors.orange.shade700;
      textColor = Colors.orange.shade700;
    }
    
    return InkWell(
      onTap: () => _changeFilter(label),
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [darkColor, lightColor],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: darkColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : textColor,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'Veg' ? Icons.eco : Icons.set_meal,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedFilter == 'Veg' ? 'Vegetarian' : 'Non-Vegetarian'} Items',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try switching to a different filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final cartItem = cart.items[item.id];
        final isInCart = cartItem != null;
        final quantity = cartItem?.quantity ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Veg/NonVeg badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.fastfood, size: 40),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item.isVeg ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          item.isVeg ? Icons.circle : Icons.change_history,
                          color: item.isVeg ? Colors.green : Colors.red,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item.description != null)
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          Text(
                            '${item.price}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Add/Update Button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isInCart)
                      ElevatedButton(
                        onPressed: item.available
                            ? () {
                                cart.addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} added to cart'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.isVeg ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          item.available ? 'ADD' : 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.isVeg
                                ? [Colors.green.shade600, Colors.green.shade400]
                                : [Colors.red.shade600, Colors.red.shade400],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                              onPressed: () {
                                if (quantity > 1) {
                                  cart.updateQuantity(item.id, quantity - 1);
                                } else {
                                  cart.removeItem(item.id);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              onPressed: () {
                                cart.updateQuantity(item.id, quantity + 1);
                              },
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}