import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/qiscus_chat_service.dart';

/// Chat controller following Single Responsibility Principle
class ChatController extends StateNotifier<ChatInitializationResult> {
  final IChatService _chatService;
  final ILoggerService _logger;

  ChatController({
    required IChatService chatService,
    required ILoggerService logger,
  })  : _chatService = chatService,
        _logger = logger,
        super(const ChatInitializationResult(state: ChatInitializationState.idle));

  /// Initialize chat with user configuration for specific channel
  Future<void> initializeChat({String? channelKey}) async {
    try {
      _logger.debug('Starting chat initialization for channel: $channelKey');
      
      // Set initializing state
      state = const ChatInitializationResult(
        state: ChatInitializationState.initializing,
      );

      // Initialize the chat service
      await _chatService.initialize();

      // Enable debug mode
      _chatService.enableDebugMode(true);

      // Set user information
      await _chatService.setUser(
        userId: AppConfig.userId,
        displayName: AppConfig.displayName,
        avatarUrl: 'https://ui-avatars.com/api/?name=${AppConfig.displayName}&background=random',
      );

      // Set channel ID based on channel key
      String channelId;
      if (channelKey != null && AppConfig.channels.containsKey(channelKey)) {
        channelId = AppConfig.channels[channelKey]!.id;
      } else {
        // Default to first channel if no key provided
        channelId = AppConfig.channels.values.first.id;
      }
      
      await _chatService.setChannelId(channelId);

      // Initiate chat
      final chatRoom = await _chatService.initiateChat();

      // Set success state
      state = ChatInitializationResult(
        state: ChatInitializationState.initialized,
        chatRoom: chatRoom,
        channelKey: channelKey,
      );

      _logger.info('Chat initialization completed successfully for channel: $channelKey');
    } catch (e, stackTrace) {
      _logger.error('Chat initialization failed', e, stackTrace);
      
      state = ChatInitializationResult(
        state: ChatInitializationState.error,
        error: e.toString(),
      );
    }
  }

  /// Retry chat initialization
  Future<void> retry() async {
    await initializeChat();
  }

  /// Reset chat state
  void reset() {
    state = const ChatInitializationResult(state: ChatInitializationState.idle);
  }
}

/// Provider for chat service
final chatServiceProvider = Provider<IChatService>((ref) {
  final logger = LoggerService();
  return QiscusChatService(
    ref: ref,
    logger: logger,
  );
});

/// Provider for chat controller
final chatControllerProvider = StateNotifierProvider<ChatController, ChatInitializationResult>((ref) {
  final logger = LoggerService();
  final chatService = ref.watch(chatServiceProvider);
  
  return ChatController(
    chatService: chatService,
    logger: logger,
  );
});
