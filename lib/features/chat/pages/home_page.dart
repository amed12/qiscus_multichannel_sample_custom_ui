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

  const HomePage({super.key, required this.title});

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

    // Use pattern matching to handle different chat states elegantly
    return switch (chatState) {
      // Idle and initializing states show a loading indicator
      ChatInitializationResult(state: ChatInitializationState.idle) ||
      ChatInitializationResult(
        state: ChatInitializationState.initializing,
      ) => ChatLoadingWidget(title: widget.title),

      // Error state shows an error message with a retry button
      ChatInitializationResult(
        state: ChatInitializationState.error,
        error: final error,
      ) =>
        ChatErrorWidget(
          title: widget.title,
          error: error ?? 'An unknown error occurred.',
          onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
        ),

      // Initialized state with a valid chat room shows the chat room UI
      ChatInitializationResult(
        state: ChatInitializationState.initialized,
        chatRoom: final chatRoom?,
      ) =>
        ChatRoomWidget(title: widget.title, chatRoom: chatRoom),

      // Handle the case where initialization finished but the chat room is null
      _ => ChatErrorWidget(
        title: widget.title,
        error: 'Chat room could not be initialized.',
        onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
      ),
    };
  }
}
