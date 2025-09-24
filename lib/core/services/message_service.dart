import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import 'logger_service.dart';

/// Provider for the message service
final messageServiceProvider = Provider<IMessageService>((ref) {
  return MessageService(ref);
});

/// Interface for message service
abstract class IMessageService {
  /// Generate a text message
  QMessage generateTextMessage({
    required int chatRoomId,
    required String text,
  });
  
  /// Generate a single image message
  QMessage generateImageMessage({
    required int chatRoomId,
    required String imageUrl,
    required String filePath,
    required int fileSize,
  });
  
  /// Generate a multi-image message
  QMessage generateMultiImageMessage({
    required int chatRoomId,
    required List<String> imageUrls,
    required List<File> imageFiles,
  });
  
  /// Send a message
  Future<QMessage> sendMessage(QMessage message);
}

/// Service for handling message generation and sending
class MessageService implements IMessageService {
  final Ref _ref;
  final ILoggerService _logger = LoggerService();
  
  MessageService(this._ref);
  
  @override
  QMessage generateTextMessage({
    required int chatRoomId,
    required String text,
  }) {
    return QMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatRoomId: chatRoomId,
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: QMessageType.text,
      timestamp: DateTime.now(),
      status: QMessageStatus.sending,
      previousMessageId: 0,
      extras: {},
      payload: {},
      sender: _getCurrentUser(),
    );
  }
  
  @override
  QMessage generateImageMessage({
    required int chatRoomId,
    required String imageUrl,
    required String filePath,
    required int fileSize,
  }) {
    return QMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatRoomId: chatRoomId,
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '[Image]',
      type: QMessageType.attachment,
      timestamp: DateTime.now(),
      status: QMessageStatus.sending,
      previousMessageId: 0,
      extras: {
        'file_path': filePath,
        'file_name': filePath.split('/').last,
      },
      payload: {
        'url': imageUrl,
        'file_name': filePath.split('/').last,
        'size': fileSize,
        'caption': '',
      },
      sender: _getCurrentUser(),
    );
  }
  
  @override
  QMessage generateMultiImageMessage({
    required int chatRoomId,
    required List<String> imageUrls,
    required List<File> imageFiles,
  }) {
    // Create a custom message type for multiple images
    final message = QMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatRoomId: chatRoomId,
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '[Multiple Images]',
      type: QMessageType.custom,
      timestamp: DateTime.now(),
      status: QMessageStatus.sending,
      previousMessageId: 0,
      extras: {
        'is_multiple_images': 'true',
        'image_count': imageUrls.length.toString(),
      },
      payload: {
        'type': 'multi_images',
        'content': {
          'images': List.generate(imageUrls.length, (index) {
            return {
              'url': imageUrls[index],
              'file_name': imageFiles[index].path.split('/').last,
              'size': imageFiles[index].lengthSync(),
            };
          }),
        },
      },
      sender: _getCurrentUser(),
    );
    
    return message;
  }
  
  @override
  Future<QMessage> sendMessage(QMessage message) async {
    try {
      await _ref.read(messagesNotifierProvider.notifier).sendMessage(message);
      _logger.debug('Message sent successfully: ${message.uniqueId}');
      return message;
    } catch (e) {
      _logger.error('Failed to send message', e);
      rethrow;
    }
  }
  
  // Helper method to get current user
  QUser _getCurrentUser() {
    // This would typically come from your app config or user session
    return QUser(
      id: 'user-id', // Replace with actual user ID
      name: 'User Name', // Replace with actual user name
      avatarUrl: null,
    );
  }
}
