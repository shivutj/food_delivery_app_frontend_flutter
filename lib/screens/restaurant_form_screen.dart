// lib/screens/restaurant_form_screen.dart - NEW FILE
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';

class RestaurantFormScreen extends StatefulWidget {
  final String? restaurantId; // null = create, non-null = edit
  final Map<String, dynamic>? existingData;

  const RestaurantFormScreen({
    super.key,
    this.restaurantId,
    this.existingData,
  });

  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _cuisineController;

  // ✅ Media state
  List<File> _imageFiles = [];
  List<String> _existingImageUrls = [];
  File? _videoFile;
  String? _existingVideoUrl;
  VideoPlayerController? _videoController;

  // ✅ Location state
  Map<String, dynamic>? _selectedLocation;

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.existingData?['description'] ?? '');
    _phoneController = TextEditingController(text: widget.existingData?['phone'] ?? '');
    _cuisineController = TextEditingController(text: widget.existingData?['cuisine'] ?? '');

    // Load existing data
    if (widget.existingData != null) {
      final images = widget.existingData!['images'];
      if (images is List) {
        _existingImageUrls = List<String>.from(images);
      }
      _existingVideoUrl = widget.existingData!['video'];
      _selectedLocation = widget.existingData!['location'];
    }
  }

  // ✅ Pick images (max 5)
  Future<void> _pickImages() async {
    if (_imageFiles.length + _existingImageUrls.length >= 5) {
      _showError('Maximum 5 images allowed');
      return;
    }

    final images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final remainingSlots = 5 - (_imageFiles.length + _existingImageUrls.length);
      final newImages = images.take(remainingSlots).map((xFile) => File(xFile.path)).toList();
      
      setState(() {
        _imageFiles.addAll(newImages);
      });
    }
  }

  // ✅ Remove image
  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _imageFiles.removeAt(index);
      }
    });
  }

  // ✅ Pick video
  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      final file = File(video.path);
      final fileSize = await file.length();

      // ✅ Check size (max 50MB)
      if (fileSize > 50 * 1024 * 1024) {
        _showError('Video size must be less than 50MB');
        return;
      }

      setState(() {
        _videoFile = file;
        _existingVideoUrl = null;
        _videoController?.dispose();
      });

      // Initialize video player
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      setState(() {});
    }
  }

  // ✅ Remove video
  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _existingVideoUrl = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  // ✅ Pick location
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocation != null
              ? LatLng(
                  _selectedLocation!['latitude'],
                  _selectedLocation!['longitude'],
                )
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  // ✅ Save restaurant
  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      _showError('Please select restaurant location');
      return;
    }

    if (_imageFiles.isEmpty && _existingImageUrls.isEmpty) {
      _showError('Please add at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Upload new images
      List<String> uploadedImageUrls = List.from(_existingImageUrls);
      
      if (_imageFiles.isNotEmpty) {
        setState(() => _isUploading = true);
        for (var imageFile in _imageFiles) {
          final url = await _apiService.uploadImage(imageFile);
          if (url != null) {
            uploadedImageUrls.add(url);
          }
        }
        setState(() => _isUploading = false);
      }

      // ✅ Upload new video
      String? videoUrl = _existingVideoUrl;
      if (_videoFile != null) {
        setState(() => _isUploading = true);
        videoUrl = await _apiService.uploadVideo(_videoFile!);
        setState(() => _isUploading = false);
      }

      // ✅ Save restaurant data
      final restaurantData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cuisine': _cuisineController.text.trim(),
        'images': uploadedImageUrls,
        'video': videoUrl,
        'location': _selectedLocation,
      };

      bool success;
      if (widget.restaurantId == null) {
        success = await _apiService.createRestaurant(restaurantData);
      } else {
        success = await _apiService.updateRestaurant(widget.restaurantId!, restaurantData);
      }

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true);
      } else {
        _showError('Failed to save restaurant');
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
    final isEdit = widget.restaurantId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Restaurant' : 'Create Restaurant'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ IMAGES SECTION (Max 5)
                    _buildSectionHeader('Images (Max 5)', Icons.image),
                    const SizedBox(height: 8),
                    _buildImagesGrid(),
                    const SizedBox(height: 24),

                    // ✅ VIDEO SECTION
                    _buildSectionHeader('Video (Optional)', Icons.videocam),
                    const SizedBox(height: 8),
                    _buildVideoSection(),
                    const SizedBox(height: 24),

                    // ✅ LOCATION SECTION
                    _buildSectionHeader('Location (Required)', Icons.location_on),
                    const SizedBox(height: 8),
                    _buildLocationSection(),
                    const SizedBox(height: 24),

                    // ✅ BASIC INFO
                    _buildSectionHeader('Restaurant Details', Icons.restaurant),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cuisineController,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fastfood),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ✅ SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _saveRestaurant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Uploading...', style: TextStyle(color: Colors.white)),
                                ],
                              )
                            : Text(
                                isEdit ? 'Update Restaurant' : 'Create Restaurant',
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildImagesGrid() {
    final totalImages = _existingImageUrls.length + _imageFiles.length;
    final canAddMore = totalImages < 5;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing images
        ..._existingImageUrls.asMap().entries.map((entry) {
          return _buildImageTile(
            imageUrl: entry.value,
            onRemove: () => _removeImage(entry.key, isExisting: true),
          );
        }),
        // New images
        ..._imageFiles.asMap().entries.map((entry) {
          return _buildImageTile(
            imageFile: entry.value,
            onRemove: () => _removeImage(entry.key),
          );
        }),
        // Add button
        if (canAddMore)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: Colors.grey.shade600),
                  const SizedBox(height: 4),
                  Text('${totalImages}/5', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({String? imageUrl, File? imageFile, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: imageFile != null ? FileImage(imageFile) : NetworkImage(imageUrl!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    if (_videoFile != null && _videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _removeVideo,
              style: IconButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      );
    } else if (_existingVideoUrl != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(child: Icon(Icons.play_circle_outline, size: 64, color: Colors.grey.shade600)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _removeVideo,
                style: IconButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: _pickVideo,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text('Tap to add video', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('Max 50MB, 60 seconds', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedLocation != null
                    ? _selectedLocation!['address']
                    : 'Tap to select location',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedLocation != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.edit, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _cuisineController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}