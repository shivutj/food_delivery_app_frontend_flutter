// lib/screens/restaurant_form_screen.dart - WITH IMAGE GALLERY (UP TO 5)
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

    // ✅ Load existing images
    if (widget.initialData?.images != null && widget.initialData!.images.isNotEmpty) {
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

  // ✅ Remove image from gallery
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

      // ✅ Upload new image files
      if (_imageFiles.isNotEmpty) {
        print('📤 Uploading ${_imageFiles.length} images...');
        
        for (int i = 0; i < _imageFiles.length; i++) {
          final uploaded = await _apiService.uploadImage(_imageFiles[i]);
          if (uploaded != null) {
            finalImageUrls.add(uploaded);
            print('✅ Image ${i + 1}/${_imageFiles.length} uploaded');
          } else {
            _showError('Failed to upload image ${i + 1}');
          }
        }
      }

      setState(() => _isUploading = false);

      if (finalImageUrls.isEmpty) {
        _showError('No images to save');
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Upload video (optional)
      String? finalVideoUrl;
      if (_videoFile != null) {
        print('📤 Uploading video...');
        finalVideoUrl = await _apiService.uploadVideo(_videoFile!);
        if (finalVideoUrl != null) {
          print('✅ Video uploaded');
        }
      } else if (_videoUrl != null && _videoUrl!.isNotEmpty) {
        finalVideoUrl = _videoUrl;
      }

      // ✅ Prepare data
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'images': finalImageUrls, // Array of image URLs
        'image': finalImageUrls[0], // Primary image (first one)
      };

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

      print('📦 Sending data: ${data.keys.toList()}');
      print('   Images count: ${finalImageUrls.length}');

      // ✅ Create or Update
      bool success;
      if (widget.initialData == null) {
        print('➕ Creating restaurant...');
        success = await _apiService.createRestaurant(data);
      } else {
        print('✏️ Updating restaurant...');
        success = await _apiService.updateRestaurant(widget.restaurantId!, data);
      }

      setState(() => _isLoading = false);

      if (success) {
        print('✅ Restaurant saved successfully');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant saved successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError('Failed to save restaurant');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
      print('❌ Error: $e');
      _showError('Error: ${e.toString()}');
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
    final totalImages = _imageFiles.length + _imageUrls.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Restaurant' : 'Create Restaurant'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading ? 'Uploading images...' : 'Saving...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ Image Gallery Display
                    if (totalImages > 0) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: totalImages,
                          itemBuilder: (context, index) {
                            final isFile = index < _imageUrls.length ? false : true;
                            final fileIndex = isFile ? index - _imageUrls.length : index;

                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isFile
                                        ? Image.file(
                                            _imageFiles[fileIndex],
                                            width: 180,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: _imageUrls[fileIndex],
                                            width: 180,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                            errorWidget: (_, __, ___) => const Icon(
                                              Icons.error,
                                              size: 48,
                                            ),
                                          ),
                                  ),
                                  // Remove button
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(fileIndex, isFile),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Primary badge
                                  if (index == 0)
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'PRIMARY',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ✅ Add Images Button
                    OutlinedButton.icon(
                      onPressed: totalImages < 5 ? _pickImages : null,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(
                        totalImages == 0
                            ? 'Add Images (Required)'
                            : 'Add More Images ($totalImages/5)',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Add up to 5 images (5MB each)\n• First image will be primary\n• Swipe to see all in preview',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: Text(
                        _videoFile != null || _videoUrl != null
                            ? 'Change Video'
                            : 'Add Video (Optional)',
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.red),
                        title: Text(_address ?? 'Select Location (Optional)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _pickLocation,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveRestaurant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Update Restaurant' : 'Create Restaurant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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