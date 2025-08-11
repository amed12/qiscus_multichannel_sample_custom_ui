import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import 'chat_service.dart';
import 'logger_service.dart';

/// Qiscus chat service implementation following Dependency Inversion Principle
class QiscusChatService implements IChatService {
  final Ref _ref;
  final ILoggerService _logger;
  IQMultichannel? _provider;

  QiscusChatService({
    required Ref ref,
    required ILoggerService logger,
  })  : _ref = ref,
        _logger = logger;

  @override
  Future<void> initialize() async {
    try {
      _logger.debug('Initializing Qiscus chat service...');
      
      // Wait for provider to be ready
      await Future.delayed(const Duration(seconds: 2));
      
      // Try to access the provider safely
      try {
        _provider = _ref.read(QMultichannel.provider);
      } catch (e) {
        _logger.warning('Error accessing provider on first attempt: $e');
        _logger.debug('Waiting longer and trying again...');
        await Future.delayed(const Duration(seconds: 2));
        _provider = _ref.read(QMultichannel.provider);
      }

      if (_provider == null) {
        throw Exception('Failed to get QMultichannel provider');
      }

      _logger.debug('Provider obtained successfully');
      
      // Log provider configuration for debugging
      try {
        final appId = _ref.read(appIdProvider);
        final sdkBaseUrl = _ref.read(sdkBaseUrlProvider);
        _logger.debug('App ID from provider: $appId');
        _logger.debug('SDK Base URL: $sdkBaseUrl');
      } catch (e) {
        _logger.warning('Could not read provider details: $e');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize chat service', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setUser({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    if (_provider == null) {
      throw Exception('Chat service not initialized');
    }

    _logger.debug('Setting user: $userId - $displayName');
    
    _provider!.setUser(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    // Wait to ensure user info is processed
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> setChannelId(String channelId) async {
    if (_provider == null) {
      throw Exception('Chat service not initialized');
    }

    if (channelId.isNotEmpty) {
      _logger.debug('Setting channel ID: $channelId');
      _provider!.setChannelId(channelId);
    }
  }

  @override
  void enableDebugMode(bool enabled) {
    if (_provider == null) {
      throw Exception('Chat service not initialized');
    }

    _provider!.enableDebugMode(enabled);
    _logger.debug('Debug mode enabled: $enabled');
  }

  @override
  Future<QChatRoom> initiateChat() async {
    if (_provider == null) {
      throw Exception('Chat service not initialized');
    }

    _logger.debug('Initiating chat...');

    // Wait before initiating chat
    await Future.delayed(const Duration(seconds: 1));

    try {
      final chatRoom = await _provider!.initiateChat();
      _logger.info('Chat initiated successfully - Room: ${chatRoom.name} (ID: ${chatRoom.id})');
      return chatRoom;
    } catch (e) {
      _logger.warning('Error during initiateChat(): $e');
      _logger.debug('Retrying after delay...');
      
      // Try once more with a delay
      await Future.delayed(const Duration(seconds: 2));
      final chatRoom = await _provider!.initiateChat();
      _logger.info('Chat initiated successfully on retry - Room: ${chatRoom.name} (ID: ${chatRoom.id})');
      return chatRoom;
    }
  }
}
