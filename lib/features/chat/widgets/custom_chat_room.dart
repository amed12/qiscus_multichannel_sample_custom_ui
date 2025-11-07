import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import 'package:date_format/date_format.dart';
import 'package:grouped_list/grouped_list.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/providers/replied_message_provider.dart';
import 'image_attachment_widget.dart';
import 'multi_image_message_widget.dart';

/// Custom chat room widget built from scratch following Qiscus patterns
/// Following Single Responsibility Principle - handles chat UI and messaging
class CustomChatRoom extends ConsumerStatefulWidget {
  const CustomChatRoom({
    super.key,
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
      // Log initial message count for debugging
      final messages = ref.read(messagesNotifierProvider);
      _logger.debug('Chat room initialized with ${messages.length} messages');
      
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    // Log message count before disposal for debugging
    final messages = ref.read(messagesNotifierProvider);
    _logger.debug('Disposing chat room with ${messages.length} messages');
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Send a text message using Qiscus SDK patterns
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
      final qiscus = ref.read(qiscusSDKProvider);
      final roomId = await ref.read(roomIdProvider.future);
      final repliedMessage = ref.read(repliedMessageProvider);
      
      // Send text message if available - following SDK pattern
      if (hasText) {
        final QMessage textMessage;
        
        // Check if replying to a message (EXACTLY like SDK)
        if (repliedMessage != null) {
          // Use generateReplyMessage for reply
          textMessage = qiscus.generateReplyMessage(
            chatRoomId: roomId,
            text: messageText,
            repliedMessage: repliedMessage,
          );
          
          // Clear replied message after using it
          ref.read(repliedMessageProvider.notifier).state = null;
          
          _logger.debug('Sending reply message to: ${repliedMessage.text}');
        } else {
          // Use generateMessage for normal message
          textMessage = qiscus.generateMessage(
            chatRoomId: roomId,
            text: messageText,
          );
          
          _logger.debug('Sending normal text message');
        }
        
        // Send using messagesNotifierProvider like SDK does
        await ref.read(messagesNotifierProvider.notifier).sendMessage(textMessage);
        
        // Synchronize after sending (important!)
        qiscus.synchronize();
        
        _logger.debug('Message sent successfully');
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

  /// Upload and send selected images following SDK pattern
  /// This follows the exact pattern from uploader_provider.dart:
  /// 1. Upload using qiscus.upload() stream for real-time progress
  /// 2. Use generateFileAttachmentMessage() after upload
  /// 3. Send via messagesNotifierProvider
  /// 4. Call synchronize() after sending
  /// 
  /// @param imageFiles List of File objects to upload and send
  Future<void> _uploadAndSendImages(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final qiscus = ref.read(qiscusSDKProvider);
      final roomId = await ref.read(roomIdProvider.future);
      
      // Upload each image following SDK pattern
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        
        // Show upload progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploading image ${i + 1} of ${imageFiles.length}...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        
        // Upload using SDK's upload stream (like uploader_provider.dart)
        var cancelToken = CancelToken();
        var stream = qiscus.upload(file, cancelToken: cancelToken);
        
        await for (var data in stream) {
          if (data.data != null) {
            // Upload complete - generate file attachment message
            final message = qiscus.generateFileAttachmentMessage(
              chatRoomId: roomId,
              caption: '',
              url: data.data!,
            );
            
            // Send message using messagesNotifierProvider (SDK pattern)
            await ref.read(messagesNotifierProvider.notifier).sendMessage(message);
            
            // Synchronize after sending (important!)
            qiscus.synchronize();
            
            _logger.debug('Image ${i + 1} sent successfully');
          } else {
            // Update progress
            final progress = (data.progress * 100).toInt();
            _logger.debug('Upload progress: $progress%');
          }
        }
      }
      
      // Reset uploading state
      setState(() {
        _isUploading = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${imageFiles.length} image(s) sent successfully')),
        );
      }
      
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      _logger.error('Failed to upload images', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
  /// With reverse: true, bottom is at minScrollExtent (position 0)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
  
  /// Scroll to specific message by ID
  void _scrollToMessage(int? messageId) {
    if (messageId == null) return;
    
    // Use postFrameCallback to ensure widget is still mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final messages = ref.read(mappedMessagesProvider);
      final index = messages.indexWhere((m) => m.id == messageId);
      
      if (index == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message not found')),
          );
        }
        return;
      }
      
      // Calculate approximate position
      // Each message is roughly 80-100 pixels, use 90 as average
      final estimatedPosition = index * 90.0;
      
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          estimatedPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Keep messagesNotifierProvider alive to prevent state loss on navigation
    ref.listen(messagesNotifierProvider, (_, __) {});
    
    // EXACTLY like SDK: Track load more state in build() method
    var isAbleToLoadMore = false;
    var lastCountMessage = 0;
    
    // Follow SDK pattern: watch providers
    final base = appThemeConfigProvider.select((v) => v.baseColor);
    final baseBgColor = ref.watch(base);
    final messages = ref.watch(mappedMessagesProvider);
    final room = ref.watch(roomProvider.select((v) => v.whenData((v) => v.room).value));
    
    // EXACTLY like SDK: isAbleToLoadMore logic
    isAbleToLoadMore = lastCountMessage < messages.length;
    
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // EXACTLY like SDK: Load more at maxScrollExtent
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              isAbleToLoadMore) {
            ref.read(messagesNotifierProvider.notifier).loadMoreMessage();
            isAbleToLoadMore = false;
          }
          return false;
        },
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: baseBgColor,
                child: buildMessageList(messages, room),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatEmpty() {
    var theme = ref.watch(appThemeConfigProvider);
    return Container(
      color: theme.emptyBackgroundColor,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "No Message here yet…",
            style: TextStyle(
              color: theme.emptyTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Great discussion start from greeting each others first",
            style: TextStyle(
              color: theme.emptyTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


  Widget buildMessageList(
    List<QMessage> messages,
    QChatRoom? room,
  ) {
    if (messages.isEmpty && room == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (messages.isEmpty && room != null) {
      return _buildChatEmpty();
    } else {
      return GroupedListView<QMessage, DateTime>(
        controller: _scrollController,
        reverse: true,
        elements: messages,
        groupBy: (message) => _buildGroupList(message),
        itemBuilder: (context, message) {
          return InkWell(
            child: _buildChatBubble(message),
            onLongPress: () {
              _showModalBottomSheet(message);
            },
          );
        },
        itemComparator: (item1, item2) =>
            item1.timestamp.compareTo(item2.timestamp),
        floatingHeader: true,
        useStickyGroupSeparators: true,
        groupSeparatorBuilder: (DateTime date) {
          return _buildSeparator(date);
        },
        order: GroupedListOrder.DESC,
      );
    }
  }
  
  /// Build group list by date (EXACTLY like SDK)
  DateTime _buildGroupList(QMessage message) {
    return DateTime.parse(
        formatDate(message.timestamp, [yyyy, '-', mm, '-', dd]));
  }
  
  /// Build date separator (EXACTLY like SDK)
  Widget _buildSeparator(DateTime date) {
    var theme = ref.watch(appThemeConfigProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.timeBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  formatDate(date, [DD, ', ', dd, ' ', MM, ' ', yyyy]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.timeLabelTextColor,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  
  _showModalBottomSheet(QMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25.0),
        ),
      ),
      builder: (context) {
        return Wrap(
          spacing: 2,
          children: [
            const Padding(padding: EdgeInsets.only(top: 16)),
            Visibility(
              visible: message.type == QMessageType.text ||
                  message.type == QMessageType.reply,
              child: ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Message'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Message copied"),
                  ));
                  Navigator.of(context).maybePop();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                ref.read(repliedMessageProvider.notifier).state = message;
                Navigator.of(context).maybePop();
              },
            ),
            const Padding(padding: EdgeInsets.only(bottom: 16)),
          ],
        );
      },
    );
  }

  Widget _buildChatBubble(QMessage message) {
    var accountId = ref
        .watch(accountProvider.select((v) => v.whenData((value) => value.id)));

    return accountId.when(
      data: (accountId) {
        if (message.sender.id == accountId) {
          return _buildMessageWidget(message, true);
        } else {
          return _buildMessageWidget(message, false);
        }
      },
      loading: () {
        return message.type == QMessageType.attachment 
            ? _buildImageBubble(message, false)
            : _buildTextBubble(message, false);
      },
      error: (e, _) {
        return Text(e.toString());
      },
    );
  }
  
  Widget _buildMessageWidget(QMessage message, bool isMe) {
    switch (message.type) {
      case QMessageType.text:
        return _buildTextBubble(message, isMe);
      case QMessageType.attachment:
        return _buildImageBubble(message, isMe);
      case QMessageType.custom:
        if (message.payload?['type'] == 'multi_images') {
          return _buildMultiImageBubble(message, isMe);
        }
        return _buildTextBubble(message, isMe);
      default:
        return _buildTextBubble(message, isMe);
    }
  }

  Widget _buildTextBubble(QMessage message, bool isMe) {
    final text = message.text;
    final timestamp = message.timestamp;
    final senderName = message.sender.name;
    
    // Check if this is a reply message
    final isReply = message.type == QMessageType.reply;
    
    // Extract replied message info from payload
    String? repliedUsername;
    String? repliedText;
    int? repliedMessageId;
    
    if (isReply && message.payload != null) {
      try {
        // replied_comment_message can be Map or already parsed
        final repliedData = message.payload;
        if (repliedData != null) {
          repliedUsername = repliedData['replied_comment_sender_username']?.toString();
          repliedText = repliedData['replied_comment_message']?.toString();
          repliedMessageId = repliedData['replied_comment_id'] as int?;
        }
        
        // Also check for alternative keys
        repliedUsername ??= '';
        repliedText ??= '';
        repliedMessageId ??= 0;
      } catch (e) {
        _logger.debug('Error parsing reply payload: $e');
      }
    }
    
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
                  // Show replied message indicator
                  if (isReply && repliedText != null)
                    GestureDetector(
                      onTap: repliedMessageId != null 
                          ? () => _scrollToMessage(repliedMessageId)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : Theme.of(context).primaryColor,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repliedUsername ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repliedText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
    final repliedMessage = ref.watch(repliedMessageProvider);
    
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
          // Reply indicator
          if (repliedMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${repliedMessage.sender.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          repliedMessage.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      ref.read(repliedMessageProvider.notifier).state = null;
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          
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
