import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/config/app_config.dart';

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
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Create QMessage object following Qiscus patterns
      final message = QMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        chatRoomId: widget.chatRoom.id,
        uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
        text: messageText,
        type: QMessageType.text,
        timestamp: DateTime.now(),
        status: QMessageStatus.sending,
        previousMessageId: 0,
        extras: {},
        payload: null,
        sender: QUser(
          id: AppConfig.userId,
          name: AppConfig.displayName,
          avatarUrl: null,
        ),
      );
      
      // Send message using messagesNotifierProvider like in Qiscus source
      await ref.read(messagesNotifierProvider.notifier).sendMessage(message);
      
      _logger.debug('Message sent successfully: $messageText');
      
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
    final messages = ref.watch(mappedMessagesProvider);
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
        return _buildChatBubble(message, isMe);
      },
      loading: () => _buildChatBubble(message, false),
      error: (e, _) => _buildChatBubble(message, false),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
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
