// lib/widgets/video_upload_widget.dart - VIDEO UPLOAD WITH PREVIEW
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class VideoUploadWidget extends StatefulWidget {
  final String? videoUrl;
  final Function(File) onVideoSelected;

  const VideoUploadWidget({
    super.key,
    this.videoUrl,
    required this.onVideoSelected,
  });

  @override
  State<VideoUploadWidget> createState() => _VideoUploadWidgetState();
}

class _VideoUploadWidgetState extends State<VideoUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializeNetworkVideo();
    }
  }

  Future<void> _initializeNetworkVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl!),
    );
    await _videoController!.initialize();
    setState(() {});
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60), // 1 minute max
      );

      if (video != null) {
        final file = File(video.path);
        
        // Check file size (max 50MB)
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          _showError('Video size must be less than 50MB');
          return;
        }

        setState(() {
          _videoFile = file;
          _videoController?.dispose();
        });

        // Initialize video player
        _videoController = VideoPlayerController.file(_videoFile!);
        await _videoController!.initialize();
        setState(() {});

        // Notify parent
        widget.onVideoSelected(file);
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _videoController != null && _videoController!.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                // Play/Pause Button
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                ),
                // Change Video Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.video_library, color: Colors.white),
                      onPressed: _pickVideo,
                    ),
                  ),
                ),
                // Progress Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.green.shade600,
                      bufferedColor: Colors.grey.shade400,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickVideo,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to select video',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max 60 seconds, 50MB',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}