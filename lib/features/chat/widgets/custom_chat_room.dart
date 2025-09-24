import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/config/app_config.dart';
import 'image_attachment_widget.dart';
import 'multi_image_message_widget.dart';

/// Custom chat room widget built from scratch following Qiscus patterns
/// Following Single Responsibility Principle - handles chat UI and messaging
class CustomChatRoom extends ConsumerStatefulWidget {
  final QChatRoom chatRoom;

  const CustomChatRoom({
    super.key,
    required this.chatRoom,
  });

  @override
  ConsumerState<CustomChatRoom> createState() => _CustomChatRoomState();
}

class _CustomChatRoomState extends ConsumerState<CustomChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ILoggerService _logger = LoggerService();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Send a text message using Qiscus patterns
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final hasText = messageText.isNotEmpty;
    final hasImages = _selectedImages.isNotEmpty;
    
    if (!hasText && !hasImages) return;
    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, images are still uploading...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _messageController.clear();
    final imagesToSend = List<File>.from(_selectedImages);
    setState(() {
      _selectedImages.clear();
    });

    try {
      // Send text message if available
      if (hasText) {
        final textMessage = QMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          chatRoomId: widget.chatRoom.id,
          uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageText,
          type: QMessageType.text,
          timestamp: DateTime.now(),
          status: QMessageStatus.sending,
          previousMessageId: 0,
          extras: {},
          payload: {},
          sender: QUser(
            id: AppConfig.userId,
            name: AppConfig.displayName,
            avatarUrl: null,
          ),
        );
        
        await ref.read(messagesNotifierProvider.notifier).sendMessage(textMessage);
        _logger.debug('Text message sent successfully');
      }
      
      // Upload and send image messages if available
      if (imagesToSend.isNotEmpty) {
        await _uploadAndSendImages(imagesToSend);
      }
      
      // Auto-scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      _logger.error('Failed to send message', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Upload and send selected images
  /// This method handles the complete flow of:
  /// 1. Uploading multiple images sequentially with progress updates
  /// 2. Determining whether to send as a single image or multi-image message
  /// 3. Creating and sending the appropriate message type
  /// 4. Providing user feedback throughout the process
  /// 
  /// @param imageFiles List of File objects to upload and send
  Future<void> _uploadAndSendImages(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Show initial upload progress indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              SizedBox(width: 16),
              Text('Uploading images...'),
            ],
          ),
          duration: Duration(minutes: 5), // Long duration as we'll dismiss it manually
        ),
      );
      
      // Get the image upload service from provider
      final imageUploadService = ref.read(imageUploadServiceProvider);
      
      // Upload images sequentially with progress callback
      final uploadedUrls = await imageUploadService.uploadMultipleImages(
        imageFiles,
        onProgress: (current, total, progress) {
          // Update progress indicator with current upload status
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading $current of $total: ${(progress * 100).toInt()}%'),
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
      );
      
      // Reset uploading state once uploads are complete
      setState(() {
        _isUploading = false;
      });
      
      // Handle case where no images were successfully uploaded
      if (uploadedUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload images')),
        );
        return;
      }
      
      // Get the message service from provider
      final messageService = ref.read(messageServiceProvider);
      
      // Determine message type based on number of images
      if (uploadedUrls.length > 1) {
        // For multiple images: create a custom multi-image message type
        // This uses a special payload format that our MultiImageMessageWidget can render
        final message = messageService.generateMultiImageMessage(
          chatRoomId: widget.chatRoom.id,
          imageUrls: uploadedUrls,
          imageFiles: imageFiles,
        );
        
        await messageService.sendMessage(message);
      } else if (uploadedUrls.isNotEmpty) {
        // For single image: use standard Qiscus attachment message type
        // This maintains compatibility with standard Qiscus UI components
        final imageFile = imageFiles.first;
        final message = messageService.generateImageMessage(
          chatRoomId: widget.chatRoom.id,
          imageUrl: uploadedUrls.first,
          filePath: imageFile.path,
          fileSize: imageFile.lengthSync(),
        );
        
        await messageService.sendMessage(message);
      }
      
      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${uploadedUrls.length} image(s) sent')),
      );
      
      // Auto-scroll to bottom after sending to show the new message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      // Log error and notify user
      _logger.error('Failed to upload images', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Removed unused _sendImageMessage method

  /// Handle image selection from the ImageAttachmentWidget
  /// This method is called when the user selects images from the gallery or camera
  /// Updates the state to store the selected images for later upload and sending
  /// 
  /// @param images List of File objects representing the selected images
  void _onImagesSelected(List<File> images) {
    setState(() {
      _selectedImages = images;
    });
    _logger.debug('Selected ${images.length} images');
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Follow Qiscus pattern: watch providers directly like in QChatRoomScreenState
    final messages = ref.watch(messagesNotifierProvider).reversed.toList();
    final room = ref.watch(roomProvider.select((v) => v.valueOrNull?.room));
    
    // Show loading if no messages and no room yet
    if (messages.isEmpty && room == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Messages list
        Expanded(
          child: messages.isEmpty && room != null
              ? _buildEmptyState()
              : _buildMessagesList(messages),
        ),
        
        // Message input
        _buildMessageInput(),
      ],
    );
  }

  /// Build empty state when no messages (following Qiscus pattern)
  Widget _buildEmptyState() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "No Message here yet…",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Great discussion start from greeting each others first",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Build messages list (following Qiscus pattern)
  Widget _buildMessagesList(List<QMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Like in Qiscus - newest messages at bottom
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Build individual message bubble (following Qiscus pattern)
  Widget _buildMessageBubble(QMessage message) {
    // Follow Qiscus pattern: use accountProvider to determine ownership
    final accountId = ref.watch(accountProvider.select((v) => v.whenData((value) => value.id)));
    
    return accountId.when(
      data: (accountId) {
        final isMe = message.sender.id == accountId;
        return _buildMessageWidget(message, isMe);
      },
      loading: () => message.type == QMessageType.attachment 
          ? _buildImageBubble(message, false)
          : _buildChatBubble(message, false),
      error: (e, _) => message.type == QMessageType.attachment 
          ? _buildImageBubble(message, false)
          : _buildChatBubble(message, false),
    );
  }
  
  /// Build message widget based on type
  /// Determines the appropriate widget to render based on message type
  /// Handles text, image attachment, and custom multi-image message types
  /// 
  /// @param message The QMessage to render
  /// @param isMe Boolean indicating if the message was sent by the current user
  Widget _buildMessageWidget(QMessage message, bool isMe) {
    switch (message.type) {
      case QMessageType.text:
        return _buildChatBubble(message, isMe);
      case QMessageType.attachment:
        return _buildImageBubble(message, isMe);
      case QMessageType.custom:
        // Check if this is our multi-image message type
        if (message.payload?['type'] == 'multi_images') {
          return _buildMultiImageBubble(message, isMe);
        }
        return _buildChatBubble(message, isMe);
      default:
        return _buildChatBubble(message, isMe);
    }
  }

  /// Build chat bubble widget
  Widget _buildChatBubble(QMessage message, bool isMe) {
    final text = message.text;
    final timestamp = message.timestamp;
    final senderName = message.sender.name;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(senderName),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(senderName),
        ],
      ),
    );
  }

  /// Build image bubble widget
  Widget _buildImageBubble(QMessage message, bool isMe) {
    final timestamp = message.timestamp;
    final senderName = message.sender.name;
    final imagePath = message.extras?['file_path']?.toString();
    final imageUrl = message.payload?['url']?.toString();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(senderName),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imagePath != null
                        ? Image.file(
                            File(imagePath),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // If local file fails, try remote URL
                              if (imageUrl != null) {
                                return Image.network(
                                  imageUrl,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImageErrorWidget();
                                  },
                                );
                              }
                              return _buildImageErrorWidget();
                            },
                          )
                        : imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImageErrorWidget();
                                },
                              )
                            : _buildImageErrorWidget(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(senderName),
        ],
      ),
    );
  }
  
  /// Build multi-image bubble widget
  /// Renders a chat bubble containing multiple images using the MultiImageMessageWidget
  /// Includes error handling to gracefully handle rendering failures
  /// 
  /// @param message The QMessage containing multi-image payload
  /// @param isMe Boolean indicating if the message was sent by the current user
  Widget _buildMultiImageBubble(QMessage message, bool isMe) {
    try {
      final timestamp = message.timestamp;
      final senderName = message.sender.name;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) _buildAvatar(senderName),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: isMe 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MultiImageMessageWidget(message: message),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isMe) _buildAvatar(senderName),
          ],
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Error building multi-image bubble', e, stackTrace);
      
      // Fallback to a simple error message bubble
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) _buildAvatar(message.sender.name),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  const Text('Could not display images'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isMe) _buildAvatar(message.sender.name),
          ],
        ),
      );
    }
  }
  
  /// Build image error widget
  Widget _buildImageErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50),
          Text('Image not found'),
        ],
      ),
    );
  }

  /// Build avatar widget
  Widget _buildAvatar(String senderName) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Build message input field
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Image attachment widget
          ImageAttachmentWidget(
            onImagesSelected: _onImagesSelected,
            selectedImages: _selectedImages,
          ),
          
          const SizedBox(height: 8),
          
          // Text input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                onPressed: _sendMessage,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
