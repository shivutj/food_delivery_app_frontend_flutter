import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';

class RestaurantFormScreen extends StatefulWidget {
  final String? restaurantId;
  final Restaurant? initialData; // ✅ FIXED

  const RestaurantFormScreen({
    super.key,
    this.restaurantId,
    this.initialData,
  });

  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;

  String? _imageUrl;
  String? _videoUrl;

  File? _imageFile;
  File? _videoFile;

  double? _latitude;
  double? _longitude;
  String? _address;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialData?.name ?? '',
    );

    _imageUrl = widget.initialData?.image;
    _videoUrl = widget.initialData?.video;

    _latitude = widget.initialData?.location?.latitude;
    _longitude = widget.initialData?.location?.longitude;
    _address = widget.initialData?.location?.address;
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

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      final file = File(video.path);
      final fileSize = await file.length();

      if (fileSize > 50 * 1024 * 1024) {
        _showError('Video size must be less than 50MB');
        return;
      }

      setState(() {
        _videoFile = file;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _latitude != null && _longitude != null
              ? LatLng(_latitude!, _longitude!)
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _address = result['address'];
      });
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image
      String finalImageUrl = _imageUrl ?? '';
      if (_imageFile != null) {
        final uploaded = await _apiService.uploadImage(_imageFile!);
        if (uploaded == null) {
          _showError('Failed to upload image');
          setState(() => _isLoading = false);
          return;
        }
        finalImageUrl = uploaded;
      }

      // Upload video
      String? finalVideoUrl = _videoUrl;
      if (_videoFile != null) {
        finalVideoUrl = await _apiService.uploadVideo(_videoFile!);
      }

      if (finalImageUrl.isEmpty) {
        _showError('Please select an image');
        setState(() => _isLoading = false);
        return;
      }

      final data = {
        'name': _nameController.text.trim(),
        'image': finalImageUrl,
        'video': finalVideoUrl,
        'location': {
          'latitude': _latitude,
          'longitude': _longitude,
          'address': _address,
        },
      };

      bool success;
      if (widget.initialData == null) {
        success = await _apiService.createRestaurant(data);
      } else {
        success =
            await _apiService.updateRestaurant(widget.restaurantId!, data);
      }

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true);
      } else {
        _showError('Failed to save restaurant');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Restaurant' : 'Create Restaurant'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(Icons.add_photo_alternate,
                                        size: 64),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Add Video (Optional)'),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.red),
                        title: Text(_address ?? 'Select Location'),
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _pickLocation,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _saveRestaurant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'Update Restaurant' : 'Create Restaurant',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
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
    super.dispose();
  }
}