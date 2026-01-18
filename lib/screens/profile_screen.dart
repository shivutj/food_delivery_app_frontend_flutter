// lib/screens/profile_screen.dart - COMPLETE FILE
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'location_picker_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // ✅ NO required user parameter

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  User? _user;
  bool _isLoading = true;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    _user = await _authService.getUserData();
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _imageFile = File(image.path));
      await _uploadProfilePhoto();
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_imageFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final imageUrl = await _apiService.uploadImage(_imageFile!);
    
    if (imageUrl != null) {
      final success = await _apiService.updateProfilePhoto(imageUrl);
      
      Navigator.pop(context);
      
      if (success) {
        await _loadProfile();
        _showSnackBar('Profile photo updated', Colors.green);
      } else {
        _showSnackBar('Failed to update photo', Colors.red);
      }
    } else {
      Navigator.pop(context);
      _showSnackBar('Failed to upload image', Colors.red);
    }
  }

  Future<void> _editAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _user?.address != null
              ? LatLng(
                  _user!.address!.latitude ?? 13.0827,
                  _user!.address!.longitude ?? 80.2707,
                )
              : null,
        ),
      ),
    );

    if (result != null) {
      await _updateAddress(result);
    }
  }

  Future<void> _updateAddress(Map<String, dynamic> locationData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final addressParts = (locationData['address'] as String).split(', ');
    
    final success = await _apiService.updateAddress(
      street: addressParts.isNotEmpty ? addressParts[0] : '',
      city: addressParts.length > 1 ? addressParts[1] : '',
      state: addressParts.length > 2 ? addressParts[2] : '',
      pincode: '600001',
      latitude: locationData['latitude'],
      longitude: locationData['longitude'],
    );

    Navigator.pop(context);

    if (success) {
      await _loadProfile();
      _showSnackBar('Address updated', Colors.green);
    } else {
      _showSnackBar('Failed to update address', Colors.red);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _user?.profilePhoto != null
                              ? NetworkImage(_user!.profilePhoto!)
                              : null,
                          child: _user?.profilePhoto == null
                              ? Text(
                                  _user?.name[0].toUpperCase() ?? '?',
                                  style: const TextStyle(fontSize: 48),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.person, 'Name', _user?.name ?? ''),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.email, 'Email', _user?.email ?? ''),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.phone, 'Phone', _user?.phone ?? ''),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.badge,
                            'Role',
                            _user?.role == 'admin' ? 'Restaurant Owner' : 'Customer',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _editAddress,
                                icon: Icon(_user?.address == null ? Icons.add : Icons.edit),
                                label: Text(_user?.address == null ? 'Add' : 'Edit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_user?.address != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_user!.address!.fullAddress),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'No address added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}