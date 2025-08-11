import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../../../core/services/logger_service.dart';
import '../widgets/custom_chat_room.dart';

/// Chat screen with full Qiscus multichannel functionality
/// Following Single Responsibility Principle - only handles chat UI
class ChatScreen extends ConsumerStatefulWidget {
  final QChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ILoggerService _logger = LoggerService();

  @override
  void initState() {
    super.initState();
    _logger.info('Opening chat room: ${widget.chatRoom.name} (ID: ${widget.chatRoom.id})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name ?? 'Chat Room',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Room ID: ${widget.chatRoom.id}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _logger.debug('Leaving chat room: ${widget.chatRoom.name}');
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showRoomInfo(context);
            },
          ),
        ],
      ),
      body: CustomChatRoom(chatRoom: widget.chatRoom),
    );
  }

  /// Show room information dialog
  void _showRoomInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Room Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room Name: ${widget.chatRoom.name ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Room ID: ${widget.chatRoom.id}'),
              const SizedBox(height: 8),
              Text('Room Type: ${widget.chatRoom.type}'),
              const SizedBox(height: 8),
              Text('Avatar URL: ${widget.chatRoom.avatarUrl}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
