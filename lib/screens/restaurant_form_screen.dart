import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/restaurant.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';

class RestaurantFormScreen extends StatefulWidget {
  final String? restaurantId;
  final Restaurant? initialData;

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

  // ✅ NEW: Dine-in controllers & state (ADDED ONLY)
  late TextEditingController _operatingHoursController;
  late TextEditingController _bookingPhoneController;
  bool _dineInAvailable = true;

  // ✅ Gallery: Up to 5 images
  final List<File> _imageFiles = [];
  final List<String> _imageUrls = [];

  String? _videoUrl;
  File? _videoFile;

  double? _latitude;
  double? _longitude;
  String? _address;

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialData?.name ?? '',
    );

    // ✅ NEW initialization (ADDED ONLY)
    _operatingHoursController = TextEditingController(
      text: widget.initialData?.operatingHours ?? '9:00 AM - 10:00 PM',
    );

    _bookingPhoneController = TextEditingController(
      text: widget.initialData?.bookingPhone ?? '',
    );

    _dineInAvailable = widget.initialData?.dineInAvailable ?? true;

    // ✅ Load existing images
    if (widget.initialData?.images != null &&
        widget.initialData!.images.isNotEmpty) {
      _imageUrls.addAll(widget.initialData!.images);
    } else if (widget.initialData?.image != null) {
      _imageUrls.add(widget.initialData!.image);
    }

    _videoUrl = widget.initialData?.video;
    _latitude = widget.initialData?.location?.latitude;
    _longitude = widget.initialData?.location?.longitude;
    _address = widget.initialData?.location?.address;
  }

  // ✅ Pick multiple images (up to 5 total)
  Future<void> _pickImages() async {
    final totalImages = _imageFiles.length + _imageUrls.length;

    if (totalImages >= 5) {
      _showError('Maximum 5 images allowed');
      return;
    }

    final remainingSlots = 5 - totalImages;

    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        for (var image in imagesToAdd) {
          _imageFiles.add(File(image.path));
        }
      });

      if (images.length > remainingSlots) {
        _showError('Only added $remainingSlots images (max 5 total)');
      }
    }
  }

  void _removeImage(int index, bool isFile) {
    setState(() {
      if (isFile) {
        _imageFiles.removeAt(index);
      } else {
        _imageUrls.removeAt(index);
      }
    });
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
        _videoUrl = null;
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

    final totalImages = _imageFiles.length + _imageUrls.length;
    if (totalImages == 0) {
      _showError('Please add at least one image');
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final List<String> finalImageUrls = List.from(_imageUrls);

      if (_imageFiles.isNotEmpty) {
        for (final file in _imageFiles) {
          final uploaded = await _apiService.uploadImage(file);
          if (uploaded != null) {
            finalImageUrls.add(uploaded);
          }
        }
      }

      setState(() => _isUploading = false);

      String? finalVideoUrl;
      if (_videoFile != null) {
        finalVideoUrl = await _apiService.uploadVideo(_videoFile!);
      } else if (_videoUrl != null && _videoUrl!.isNotEmpty) {
        finalVideoUrl = _videoUrl;
      }

      // ✅ UPDATED payload (ONLY added fields)
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'images': finalImageUrls,
        'image': finalImageUrls[0],
        'dineInAvailable': _dineInAvailable,
        'operatingHours': _operatingHoursController.text.trim(),
      };

      if (_bookingPhoneController.text.trim().isNotEmpty) {
        data['bookingPhone'] = _bookingPhoneController.text.trim();
      }

      if (finalVideoUrl != null && finalVideoUrl.isNotEmpty) {
        data['video'] = finalVideoUrl;
      }

      if (_latitude != null && _longitude != null && _address != null) {
        data['location'] = {
          'latitude': _latitude,
          'longitude': _longitude,
          'address': _address,
        };
      }

      bool success;
      if (widget.initialData == null) {
        success = await _apiService.createRestaurant(data);
      } else {
        success =
            await _apiService.updateRestaurant(widget.restaurantId!, data);
      }

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    final totalImages = _imageFiles.length + _imageUrls.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Restaurant' : 'Create Restaurant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Restaurant Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // ✅ NEW: Dine-In Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Dine-In Available'),
                  subtitle: Text(
                    _dineInAvailable
                        ? 'Customers can visit and dine at your restaurant'
                        : 'Only delivery/takeaway available',
                  ),
                  value: _dineInAvailable,
                  onChanged: (v) => setState(() => _dineInAvailable = v),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ NEW: Operating Hours
              TextFormField(
                controller: _operatingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Operating Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ NEW: Booking Phone (conditional)
              if (_dineInAvailable)
                TextFormField(
                  controller: _bookingPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Table Booking Phone (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              if (_dineInAvailable) const SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(_address ?? 'Select Location'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _pickLocation,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveRestaurant,
                child:
                    Text(isEditing ? 'Update Restaurant' : 'Create Restaurant'),
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
    _operatingHoursController.dispose();
    _bookingPhoneController.dispose();
    super.dispose();
  }
}