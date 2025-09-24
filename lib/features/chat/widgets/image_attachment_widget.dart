import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/logger_service.dart';

/// Widget for handling multiple image attachments
/// Following Single Responsibility Principle - handles only image attachment UI
class ImageAttachmentWidget extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final List<File> selectedImages;

  const ImageAttachmentWidget({
    super.key,
    required this.onImagesSelected,
    required this.selectedImages,
  });

  @override
  State<ImageAttachmentWidget> createState() => _ImageAttachmentWidgetState();
}

class _ImageAttachmentWidgetState extends State<ImageAttachmentWidget> {
  final IImageService _imageService = ImageService();
  final ILoggerService _logger = LoggerService();

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Images',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickMultipleImages();
                      },
                    ),
                    _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickFromCamera();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build source option widget
  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick multiple images from gallery
  Future<void> _pickMultipleImages() async {
    try {
      final images = await _imageService.pickMultipleImages(context: context);
      if (images.isNotEmpty) {
        final updatedImages = [...widget.selectedImages, ...images];
        widget.onImagesSelected(updatedImages);
        _logger.info('Added ${images.length} images to selection');
      }
    } catch (e) {
      _logger.error('Failed to pick multiple images', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick single image from camera
  Future<void> _pickFromCamera() async {
    try {
      final image = await _imageService.pickSingleImage(context: context, source: ImageSource.camera);
      if (image != null) {
        final updatedImages = [...widget.selectedImages, image];
        widget.onImagesSelected(updatedImages);
        _logger.info('Added camera image to selection');
      }
    } catch (e) {
      _logger.error('Failed to pick image from camera', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove image from selection
  void _removeImage(int index) {
    final updatedImages = [...widget.selectedImages];
    updatedImages.removeAt(index);
    widget.onImagesSelected(updatedImages);
    _logger.debug('Removed image at index $index');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image previews
        if (widget.selectedImages.isNotEmpty) _buildImagePreviews(),
        
        // Attachment button
        _buildAttachmentButton(),
      ],
    );
  }

  /// Build image previews
  Widget _buildImagePreviews() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.selectedImages.length,
        itemBuilder: (context, index) {
          final image = widget.selectedImages[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                
                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build attachment button
  Widget _buildAttachmentButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.attach_file,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
    );
  }
}
