import 'package:flutter/material.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../../../core/services/logger_service.dart';

/// Chat room widget following Single Responsibility Principle
class ChatRoomWidget extends StatelessWidget {
  final String title;
  final QChatRoom chatRoom;
  final ILoggerService _logger = LoggerService();

  ChatRoomWidget({
    super.key,
    this.title = 'Qiscus Chat',
    required this.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ready to chat on room ${chatRoom.name}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Room ID: ${chatRoom.id}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _logger.debug('Chat room accessed: ${chatRoom.name} (ID: ${chatRoom.id})');
          // Here you can navigate to actual chat screen or perform other actions
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}
