import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/chat_service.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_loading_widget.dart';
import '../widgets/chat_error_widget.dart';
import '../widgets/chat_room_widget.dart';

/// Home page for multi-channel chat selection
/// Following Single Responsibility Principle - handles channel selection UI
class HomePage extends ConsumerWidget {
  final String title;

  const HomePage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 40),
            Text(
              'Pilih Channel Chat',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan pilih channel yang sesuai dengan kebutuhan Anda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Channel Cards
            Expanded(
              child: ListView.builder(
                itemCount: AppConfig.channels.length,
                itemBuilder: (context, index) {
                  final channelEntry = AppConfig.channels.entries.elementAt(index);
                  final channelKey = channelEntry.key;
                  final channel = channelEntry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildChannelCard(
                      context,
                      ref,
                      channelKey,
                      channel,
                    ),
                  );
                },
              ),
            ),
            
            // Footer
            const SizedBox(height: 24),
            Text(
              'Powered by Qiscus Multichannel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build channel selection card
  Widget _buildChannelCard(
    BuildContext context,
    WidgetRef ref,
    String channelKey,
    ChannelConfig channel,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToChannel(context, ref, channelKey, channel),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Channel Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    channel.icon,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Channel Name
              Text(
                channel.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Channel Description
              Text(
                channel.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Enter Button
              ElevatedButton.icon(
                onPressed: () => _navigateToChannel(context, ref, channelKey, channel),
                icon: const Icon(Icons.chat),
                label: const Text('Masuk Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to channel chat room
  void _navigateToChannel(
    BuildContext context,
    WidgetRef ref,
    String channelKey,
    ChannelConfig channel,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelChatPage(
          channelKey: channelKey,
          channel: channel,
        ),
      ),
    );
  }
}

/// Individual channel chat page
class ChannelChatPage extends ConsumerStatefulWidget {
  final String channelKey;
  final ChannelConfig channel;

  const ChannelChatPage({
    super.key,
    required this.channelKey,
    required this.channel,
  });

  @override
  ConsumerState<ChannelChatPage> createState() => _ChannelChatPageState();
}

class _ChannelChatPageState extends ConsumerState<ChannelChatPage> {
  @override
  void initState() {
    super.initState();
    // Initialize chat for specific channel when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).initializeChat(
        channelKey: widget.channelKey,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.channel.icon),
            const SizedBox(width: 8),
            Text(widget.channel.name),
          ],
        ),
        centerTitle: true,
      ),
      body: switch (chatState) {
        ChatInitializationResult(state: ChatInitializationState.idle) ||
        ChatInitializationResult(
          state: ChatInitializationState.initializing,
        ) =>
          const ChatLoadingWidget(),
        ChatInitializationResult(
          state: ChatInitializationState.error,
          error: final error,
        ) =>
          ChatErrorWidget(
            error: error ?? 'Unknown error occurred',
            onRetry: () => ref.read(chatControllerProvider.notifier).retry(),
          ),
        ChatInitializationResult(
          state: ChatInitializationState.initialized,
          chatRoom: final chatRoom,
        ) =>
          chatRoom != null
              ? ChatRoomWidget(chatRoom: chatRoom)
              : ChatErrorWidget(
                  error: 'Chat room is null',
                  onRetry: () =>
                      ref.read(chatControllerProvider.notifier).retry(),
                ),
      },
    );
  }
}
