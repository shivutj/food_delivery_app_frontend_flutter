// lib/screens/admin_menu_screen.dart
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../models/menu.dart';
import '../services/api_service.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final ApiService _apiService = ApiService();
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final restaurants = await _apiService.getRestaurants();
    setState(() {
      _restaurants = restaurants;
      _isLoading = false;
      if (_restaurants.isNotEmpty) {
        _selectedRestaurant = _restaurants[0];
        _loadMenu();
      }
    });
  }

  Future<void> _loadMenu() async {
    if (_selectedRestaurant == null) return;
    setState(() => _isLoading = true);
    final menu = await _apiService.getMenu(_selectedRestaurant!.id);
    setState(() {
      _menuItems = menu;
      _isLoading = false;
    });
  }

  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty) {
                return;
              }

              final result = await _apiService.addMenuItem(
                _selectedRestaurant!.id,
                nameController.text,
                double.parse(priceController.text),
                categoryController.text.isEmpty
                    ? 'Main Course'
                    : categoryController.text,
                imageController.text.isEmpty
                    ? 'https://via.placeholder.com/150'
                    : imageController.text,
              );

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu item added')),
                );
                _loadMenu();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final result = await _apiService.deleteMenuItem(item.id);
              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted')),
                );
                _loadMenu();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_restaurants.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<Restaurant>(
                      value: _selectedRestaurant,
                      decoration: const InputDecoration(
                        labelText: 'Select Restaurant',
                        border: OutlineInputBorder(),
                      ),
                      items: _restaurants.map((restaurant) {
                        return DropdownMenuItem(
                          value: restaurant,
                          child: Text(restaurant.name),
                        );
                      }).toList(),
                      onChanged: (restaurant) {
                        setState(() {
                          _selectedRestaurant = restaurant;
                        });
                        _loadMenu();
                      },
                    ),
                  ),
                Expanded(
                  child: _menuItems.isEmpty
                      ? const Center(child: Text('No menu items'))
                      : ListView.builder(
                          itemCount: _menuItems.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.image,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.fastfood),
                                      );
                                    },
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.category} - ₹${item.price.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _showDeleteDialog(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenuDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}