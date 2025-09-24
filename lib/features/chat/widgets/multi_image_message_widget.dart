import 'package:flutter/material.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';

/// Widget to display multiple images in a single message
class MultiImageMessageWidget extends StatelessWidget {
  final QMessage message;
  
  const MultiImageMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Extract image URLs from the message payload
      final Map<String, dynamic>? content = message.payload?['content'] as Map<String, dynamic>?;
      
      if (content == null) {
        debugPrint('MultiImageMessageWidget: Invalid message payload structure - content is null');
        return _buildErrorWidget('Invalid message format');
      }
      
      final List<dynamic>? imagesList = content['images'] as List?;
      
      if (imagesList == null || imagesList.isEmpty) {
        debugPrint('MultiImageMessageWidget: No images found in payload');
        return _buildErrorWidget('No images to display');
      }
      
      final List<dynamic> images = imagesList;
      
      // Validate image URLs
      bool hasValidImages = false;
      for (final image in images) {
        if (image is Map && image['url'] != null && image['url'].toString().isNotEmpty) {
          hasValidImages = true;
          break;
        }
      }
      
      if (!hasValidImages) {
        debugPrint('MultiImageMessageWidget: No valid image URLs found');
        return _buildErrorWidget('Invalid image data');
      }
    
      // Determine layout based on number of images
      if (images.length == 1) {
        return _buildSingleImage(context, images[0]['url']);
      } else if (images.length == 2) {
        return _buildTwoImages(context, images);
      } else if (images.length == 3) {
        return _buildThreeImages(context, images);
      } else {
        return _buildGridImages(context, images);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in MultiImageMessageWidget: $e');
      debugPrint(stackTrace.toString());
      return _buildErrorWidget('Error displaying images');
    }
  }
  
  /// Builds an error widget when image loading fails
  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a single image view
  Widget _buildSingleImage(BuildContext context, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
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
    );
  }
  
  /// Build a two-image layout
  Widget _buildTwoImages(BuildContext context, List<dynamic> images) {
    return SizedBox(
      width: 200,
      height: 100,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                images[0]['url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Image.network(
                images[1]['url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a three-image layout
  Widget _buildThreeImages(BuildContext context, List<dynamic> images) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                images[0]['url'],
                fit: BoxFit.cover,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      images[1]['url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      images[2]['url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a grid layout for 4+ images
  Widget _buildGridImages(BuildContext context, List<dynamic> images) {
    final displayCount = images.length > 4 ? 4 : images.length;
    final hasMore = images.length > 4;
    
    return SizedBox(
      width: 200,
      height: 200,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(displayCount, (index) {
          final isLastTile = index == 3 && hasMore;
          
          return ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: index == 0 ? const Radius.circular(8) : Radius.zero,
              topRight: index == 1 ? const Radius.circular(8) : Radius.zero,
              bottomLeft: index == 2 ? const Radius.circular(8) : Radius.zero,
              bottomRight: index == 3 ? const Radius.circular(8) : Radius.zero,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  images[index]['url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
                if (isLastTile)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Text(
                        '+${images.length - 3}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
