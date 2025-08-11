import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../../../core/services/logger_service.dart';

/// Custom chat room widget built from scratch
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
  
  List<Map<String, dynamic>> _messages = [];
  final bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load initial demo messages
  void _loadInitialMessages() {
    setState(() {
      _messages = [
        {
          'id': '1',
          'text': 'Hello! How can I help you today?',
          'isMe': false,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'sender': 'Agent',
        },
        {
          'id': '2', 
          'text': 'Hi there! I have a question about your service.',
          'isMe': true,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          'sender': 'You',
        },
      ];
    });
    _scrollToBottom();
  }

  /// Send a text message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      setState(() => _isSending = true);
      
      // Add message to local list immediately
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': messageText,
        'isMe': true,
        'timestamp': DateTime.now(),
        'sender': 'You',
      };
      
      setState(() {
        _messages.add(newMessage);
      });
      
      _scrollToBottom();
      _logger.debug('Message sent: $messageText');
      
      // Simulate sending to Qiscus (replace with actual API call)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate agent response
      await Future.delayed(const Duration(seconds: 1));
      _simulateAgentResponse();
      
    } catch (e) {
      _logger.error('Failed to send message', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Simulate agent response
  void _simulateAgentResponse() {
    final responses = [
      'Thank you for your message. Let me help you with that.',
      'I understand your concern. Can you provide more details?',
      'That\'s a great question! Here\'s what I can tell you...',
      'I\'m here to assist you. What specific information do you need?',
    ];
    
    final response = responses[DateTime.now().millisecond % responses.length];
    
    final agentMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': response,
      'isMe': false,
      'timestamp': DateTime.now(),
      'sender': 'Agent',
    };
    
    setState(() {
      _messages.add(agentMessage);
    });
    
    _scrollToBottom();
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
    return Column(
      children: [
        // Messages list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessagesList(),
        ),
        
        // Message input
        _buildMessageInput(),
      ],
    );
  }

  /// Build empty state when no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Build messages list
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Build individual message bubble
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as DateTime;
    final sender = message['sender'] as String;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(sender),
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
                        sender,
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
          if (isMe) _buildAvatar(sender),
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
            onPressed: _isSending ? null : _sendMessage,
            backgroundColor: Theme.of(context).primaryColor,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
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
