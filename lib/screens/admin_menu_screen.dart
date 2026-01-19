// lib/screens/admin_menu_screen.dart - COMPLETE FIXED VERSION
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
  Restaurant? _myRestaurant;
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  bool _hasRestaurant = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // ✅ First, get restaurant owner's own restaurant
    _myRestaurant = await _apiService.getMyRestaurant();
    
    if (_myRestaurant != null) {
      _hasRestaurant = true;
      // ✅ Only load menu items for THIS restaurant
      await _loadMenuItems();
    } else {
      _hasRestaurant = false;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadMenuItems() async {
    if (_myRestaurant != null) {
      final menu = await _apiService.getMenu(_myRestaurant!.id);
      setState(() {
        _menuItems = menu;
      });
    }
  }

  Future<void> _deleteMenuItem(String menuId, String itemName) async {
    // ✅ Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // ✅ Delete item
    final success = await _apiService.deleteMenuItem(menuId);
    
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadMenuItems(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasRestaurant
              ? _buildNoRestaurantState()
              : _menuItems.isEmpty
                  ? _buildEmptyMenuState()
                  : _buildMenuList(),
      floatingActionButton: _hasRestaurant
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditMenuScreen(
                      restaurantId: _myRestaurant!.id,
                    ),
                  ),
                );
                if (result == true) {
                  await _loadMenuItems();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  // ✅ Show when owner has no restaurant yet
  Widget _buildNoRestaurantState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store,
                size: 80,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Restaurant Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You need to create your restaurant first before adding menu items.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to restaurant creation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please create your restaurant from the dashboard'),
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Show when menu is empty (no default items)
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
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Start Guide',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideStep('1', 'Add food items with name, price & image'),
                  _buildGuideStep('2', 'Set availability for each item'),
                  _buildGuideStep('3', 'Start receiving orders from customers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Show menu items list
  Widget _buildMenuList() {
    return ListView.builder(
      itemCount: _menuItems.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: ClipRRect(
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
            title: Text(item.name),
            subtitle: Text('₹${item.price.toInt()} • ${item.category}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditMenuScreen(
                          menuItem: item,
                          restaurantId: _myRestaurant!.id,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadMenuItems();
                    }
                  },
                  tooltip: 'Edit',
                ),
                // ✅ Delete Button - NOW WORKS!
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMenuItem(item.id, item.name),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}