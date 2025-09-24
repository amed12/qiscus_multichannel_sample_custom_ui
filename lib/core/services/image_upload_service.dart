import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import 'logger_service.dart';

/// Provider for the image upload service
final imageUploadServiceProvider = Provider<IImageUploadService>((ref) {
  return ImageUploadService(ref);
});

/// Interface for image upload service
abstract class IImageUploadService {
  /// Upload a single image and return the remote URL
  Future<String?> uploadSingleImage(File imageFile, {Function(double)? onProgress});
  
  /// Upload multiple images sequentially and return list of remote URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles, {Function(int, int, double)? onProgress});
}

/// Service for handling image uploads to Qiscus server
class ImageUploadService implements IImageUploadService {
  final Ref _ref;
  final ILoggerService _logger = LoggerService();
  
  ImageUploadService(this._ref);
  
  @override
  Future<String?> uploadSingleImage(File imageFile, {Function(double)? onProgress}) async {
    try {
      _logger.info('Starting image upload: ${imageFile.path}');
      
      // Get the Qiscus SDK instance
      final qiscus = await _ref.read(qiscusProvider.future);
      
      // Create a cancel token for potential cancellation
      final cancelToken = CancelToken();
      
      // Upload the file and listen to progress
      String? uploadedUrl;
      
      await for (final progress in qiscus.upload(imageFile, cancelToken: cancelToken)) {
        if (progress.data != null) {
          // Upload completed successfully
          uploadedUrl = progress.data;
          _logger.info('Image uploaded successfully: $uploadedUrl');
          break;
        } else {
          // Upload in progress
          if (onProgress != null) {
            onProgress(progress.progress);
          }
          _logger.debug('Upload progress: ${progress.progress * 100}%');
        }
      }
      
      return uploadedUrl;
    } catch (e) {
      _logger.error('Failed to upload image', e);
      return null;
    }
  }
  
  @override
  Future<List<String>> uploadMultipleImages(
    List<File> files, 
    {
      Function(int, int, double)? onProgress,
    }
  ) async {
    List<String> uploadedUrls = [];
    int totalFiles = files.length;
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        // Check if file exists and is readable
        if (!file.existsSync()) {
          _logger.error('File does not exist or is not accessible', null);
          continue;
        }
        
        // Calculate progress based on completed uploads
        final progressCallback = onProgress != null 
            ? (double progress) => onProgress(i + 1, totalFiles, progress)
            : null;
            
        final url = await uploadSingleImage(
          file,
          onProgress: progressCallback,
        );
        
        if (url == null || url.isEmpty) {
          _logger.error('Upload returned empty URL', null);
          continue;
        }
        
        uploadedUrls.add(url);
        
      } catch (e) {
        _logger.error('Failed to upload image ${i + 1}', e);
        // Continue with next image even if one fails
      }
    }
    
    return uploadedUrls;
  }
}
