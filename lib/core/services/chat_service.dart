import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';

/// Chat service interface following Interface Segregation Principle
abstract class IChatService {
  Future<void> initialize();
  Future<QChatRoom> initiateChat();
  Future<void> setUser({required String userId, required String displayName, String? avatarUrl});
  Future<void> setChannelId(String channelId);
  void enableDebugMode(bool enabled);
}

/// Chat initialization state
enum ChatInitializationState {
  idle,
  initializing,
  initialized,
  error,
}

/// Chat initialization result
class ChatInitializationResult {
  final ChatInitializationState state;
  final QChatRoom? chatRoom;
  final String? error;
  final String? channelKey;

  const ChatInitializationResult({
    required this.state,
    this.chatRoom,
    this.error,
    this.channelKey,
  });

  bool get isSuccess => state == ChatInitializationState.initialized && chatRoom != null;
  bool get isError => state == ChatInitializationState.error;
  bool get isInitializing => state == ChatInitializationState.initializing;
}
