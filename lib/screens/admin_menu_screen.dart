// lib/screens/admin_menu_screen.dart - WITH VEG/NON-VEG FILTER
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import 'add_edit_menu_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final ApiService _apiService = ApiService();
  List<Restaurant> _restaurants = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _selectedRestaurantId;
  
  // ✅ NEW: Filter state
  String _filterType = 'all'; // 'all', 'veg', 'non-veg'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _restaurants = await _apiService.getRestaurants();
    if (_restaurants.isNotEmpty) {
      _selectedRestaurantId = _restaurants.first.id;
      await _loadMenuItems();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMenuItems() async {
    if (_selectedRestaurantId != null) {
      final menu = await _apiService.getMenu(_selectedRestaurantId!);
      setState(() {
        _menuItems = menu;
      });
    }
  }

  // ✅ Filter menu items based on veg/non-veg
  List<MenuItem> get _filteredMenuItems {
    if (_filterType == 'all') return _menuItems;
    if (_filterType == 'veg') {
      return _menuItems.where((item) => item.isVeg).toList();
    }
    return _menuItems.where((item) => !item.isVeg).toList();
  }

  Future<void> _deleteMenuItem(String menuId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _apiService.deleteMenuItem(menuId);
      
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadMenuItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete item. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyMenuState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Menu is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding delicious items to your menu!\n\nTap the + button below to add your first food item.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.green.shade600, Colors.green.shade400],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Restaurant Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRestaurantId,
                    decoration: const InputDecoration(
                      labelText: 'Select Restaurant',
                      border: OutlineInputBorder(),
                    ),
                    items: _restaurants.map((restaurant) {
                      return DropdownMenuItem(
                        value: restaurant.id,
                        child: Text(restaurant.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRestaurantId = value;
                        _loadMenuItems();
                      });
                    },
                  ),
                ),

                // ✅ Filter Chips
                if (_menuItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Filter:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', 'all', Icons.restaurant_menu),
                                const SizedBox(width: 8),
                                _buildFilterChip('Veg', 'veg', Icons.eco, Colors.green),
                                const SizedBox(width: 8),
                                _buildFilterChip('Non-Veg', 'non-veg', Icons.restaurant, Colors.red),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Menu Items List
                Expanded(
                  child: _filteredMenuItems.isEmpty
                      ? _buildEmptyMenuState()
                      : RefreshIndicator(
                          onRefresh: _loadMenuItems,
                          child: ListView.builder(
                            itemCount: _filteredMenuItems.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final item = _filteredMenuItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.image,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.fastfood),
                                            );
                                          },
                                        ),
                                      ),
                                      // ✅ Veg/Non-Veg Indicator
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: item.isVeg ? Colors.green : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            item.isVeg ? Icons.circle : Icons.circle,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isVeg 
                                            ? Colors.green.shade50 
                                            : Colors.red.shade50,
                                          border: Border.all(
                                            color: item.isVeg 
                                              ? Colors.green.shade600 
                                              : Colors.red.shade600,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.isVeg ? 'VEG' : 'NON-VEG',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.isVeg 
                                              ? Colors.green.shade700 
                                              : Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '₹${item.price} • ${item.category}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddEditMenuScreen(
                                                menuItem: item,
                                                restaurantId: _selectedRestaurantId!,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            await _loadMenuItems();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteMenuItem(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedRestaurantId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditMenuScreen(
                      restaurantId: _selectedRestaurantId!,
                    ),
                  ),
                );
                if (result == true) {
                  await _loadMenuItems();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              backgroundColor: Colors.green.shade600,
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, [Color? color]) {
    final isSelected = _filterType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected 
              ? Colors.white 
              : (color ?? (isDark ? Colors.white70 : Colors.black87)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      selectedColor: color ?? Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
    );
  }
}