import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chat_service.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_loading_widget.dart';
import '../widgets/chat_error_widget.dart';
import '../widgets/chat_room_widget.dart';

/// Home page following Single Responsibility Principle
class HomePage extends ConsumerStatefulWidget {
  final String title;

  const HomePage({
    super.key,
    required this.title,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    
    // Initialize chat after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).initializeChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return switch (chatState.state) {
      ChatInitializationState.idle ||
      ChatInitializationState.initializing => 
        ChatLoadingWidget(title: widget.title),
      
      ChatInitializationState.error => 
        ChatErrorWidget(
          title: widget.title,
          error: chatState.error ?? 'Unknown error',
          onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
        ),
      
      ChatInitializationState.initialized => 
        chatState.chatRoom != null
          ? ChatRoomWidget(
              title: widget.title,
              chatRoom: chatState.chatRoom!,
            )
          : ChatErrorWidget(
              title: widget.title,
              error: 'Chat room not available',
              onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
            ),
    };
  }
}
