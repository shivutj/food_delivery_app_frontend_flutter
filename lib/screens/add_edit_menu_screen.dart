// lib/screens/add_edit_menu_screen.dart - WITH VEG/NON-VEG TOGGLE
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class AddEditMenuScreen extends StatefulWidget {
  final MenuItem? menuItem;
  final String restaurantId;

  const AddEditMenuScreen({
    super.key,
    this.menuItem,
    required this.restaurantId,
  });

  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;

  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _available = true;
  bool _isVeg = true; // ✅ NEW: Veg/Non-Veg toggle

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem?.name ?? '');
    _priceController = TextEditingController(
      text: widget.menuItem?.price.toInt().toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.menuItem?.category ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.menuItem?.description ?? '',
    );
    _imageUrl = widget.menuItem?.image;
    _available = widget.menuItem?.available ?? true;
    _isVeg = widget.menuItem?.isVeg ?? true; // ✅ Load existing value
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        final uploadedUrl = await _apiService.uploadImage(_imageFile!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          _showError('Failed to upload image');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (finalImageUrl.isEmpty) {
        _showError('Please select an image');
        setState(() => _isLoading = false);
        return;
      }

      final priceValue = int.parse(_priceController.text.trim());

      final menuItem = MenuItem(
        id: widget.menuItem?.id ?? '',
        restaurantId: widget.restaurantId,
        name: _nameController.text.trim(),
        price: priceValue,
        image: finalImageUrl,
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        available: _available,
        isVeg: _isVeg, // ✅ Save veg/non-veg status
        video: widget.menuItem?.video,
      );

      bool success;
      if (widget.menuItem == null) {
        success = await _apiService.addMenuItem(menuItem);
      } else {
        success = await _apiService.updateMenuItem(menuItem.id, menuItem);
      }

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true);
      } else {
        _showError('Failed to save menu item');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuItem != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(_imageUrl!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 64, color: Colors.grey[600]),
                                      const SizedBox(height: 8),
                                      Text('Tap to select image',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ✅ VEG/NON-VEG TOGGLE
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: _isVeg ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isVeg ? 'Pure Vegetarian' : 'Non-Vegetarian',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isVeg,
                              onChanged: (value) {
                                setState(() => _isVeg = value);
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant_menu),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                        hintText: 'e.g., 299',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter price';
                        }
                        final price = int.tryParse(value);
                        if (price == null) {
                          return 'Please enter valid price';
                        }
                        if (price <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        hintText: 'e.g., Main Course, Dessert',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Availability Toggle
                    SwitchListTile(
                      title: const Text('Available'),
                      subtitle: Text(_available ? 'Item is available' : 'Item is unavailable'),
                      value: _available,
                      onChanged: (value) {
                        setState(() => _available = value);
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveMenuItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Item' : 'Add Item',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}