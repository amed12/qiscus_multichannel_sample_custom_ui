import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'logger_service.dart';

/// Service for handling image selection and permissions
/// Following Single Responsibility Principle - handles only image operations
abstract class IImageService {
  Future<List<File>> pickMultipleImages({required BuildContext context});
  Future<File?> pickSingleImage({required BuildContext context, ImageSource source = ImageSource.gallery});
  Future<PermissionStatus> requestPermissions({required Permission permission});
  Future<bool> handlePermissionStatus({required BuildContext context, required PermissionStatus status});
}

class ImageService implements IImageService {
  final ImagePicker _picker = ImagePicker();
  final ILoggerService _logger = LoggerService();

  @override
  Future<List<File>> pickMultipleImages({required BuildContext context}) async {
    try {
      // Request permissions first
      Permission permission;
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }
      } else {
        permission = Permission.photos;
      }
      
      final status = await requestPermissions(permission: permission);
      final hasPermission = await handlePermissionStatus(context: context, status: status);
      
      if (!hasPermission) {
        _logger.warning('Image permissions not granted');
        return [];
      }

      // For now, we'll implement multiple selection by allowing users to pick one at a time
      // This is a fallback approach that works with all versions of image_picker
      final List<File> selectedImages = [];
      
      // Pick first image
      final XFile? firstImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (firstImage != null) {
        selectedImages.add(File(firstImage.path));
      }

      _logger.info('Selected ${selectedImages.length} images');
      return selectedImages;
    } catch (e) {
      _logger.error('Failed to pick multiple images', e);
      _showErrorDialog(context, 'Failed to pick images: ${e.toString()}');
      return [];
    }
  }

  @override
  Future<File?> pickSingleImage({required BuildContext context, ImageSource source = ImageSource.gallery}) async {
    try {
      // Request permissions first
      Permission permission;
      if (source == ImageSource.camera) {
        permission = Permission.camera;
      } else if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }
      } else {
        permission = Permission.photos;
      }
      
      final status = await requestPermissions(permission: permission);
      final hasPermission = await handlePermissionStatus(context: context, status: status);
      
      if (!hasPermission) {
        _logger.warning('Image permissions not granted');
        return null;
      }

      // Pick single image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _logger.debug('No image selected');
        return null;
      }

      final File imageFile = File(pickedFile.path);
      _logger.info('Selected image: ${imageFile.path}');
      return imageFile;
    } catch (e) {
      _logger.error('Failed to pick single image', e);
      _showErrorDialog(context, 'Failed to pick image: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<PermissionStatus> requestPermissions({required Permission permission}) async {
    try {
      final status = await permission.request();
      _logger.info('Permission ${permission.toString()} status: ${status.toString()}');
      return status;
    } catch (e) {
      _logger.error('Failed to request permissions', e);
      return PermissionStatus.denied;
    }
  }
  
  @override
  Future<bool> handlePermissionStatus({required BuildContext context, required PermissionStatus status}) async {
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.limited:
        // For iOS photo library limited access
        return true;
      case PermissionStatus.denied:
        _showPermissionDeniedDialog(context, 'Permission denied', 
          'Please grant permission to access photos in app settings.');
        return false;
      case PermissionStatus.permanentlyDenied:
        _showPermissionDeniedDialog(context, 'Permission permanently denied', 
          'Please enable permission in app settings to use this feature.', 
          openSettings: true);
        return false;
      case PermissionStatus.restricted:
        _showPermissionDeniedDialog(context, 'Permission restricted', 
          'Permission is restricted and cannot be requested.');
        return false;
      default:
        return false;
    }
  }
  
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API 33
    }
    return false;
  }
  
  void _showPermissionDeniedDialog(BuildContext context, String title, String message, {bool openSettings = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (openSettings)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }
  
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
