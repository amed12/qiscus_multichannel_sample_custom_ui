# 🚀 Complete Tutorial: Building Custom Chat UI with Qiscus Multichannel & Riverpod

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Understanding Riverpod State Management](#understanding-riverpod-state-management)
3. [Project Architecture Overview](#project-architecture-overview)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [Before Entering Chat Room](#before-entering-chat-room)
6. [Building the Custom Chat Room Widget](#building-the-custom-chat-room-widget)
7. [Advanced Features](#advanced-features)
8. [Testing & Debugging](#testing--debugging)
9. [Best Practices](#best-practices)

---

## 📚 Prerequisites

### Required Knowledge
- **Flutter Basics**: Widgets, State Management, Navigation
- **Dart Language**: Async/await, Classes, Interfaces
- **Basic Understanding**: HTTP requests, File handling

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ...
  qiscus_multichannel_widget: ^latest_version
  logger: ... => optional just for example purpose
```

---

## 🧠 Understanding Riverpod State Management

### What is Riverpod?
Riverpod is a reactive caching and data-binding framework for Flutter. Think of it as a more powerful and safer version of Provider.

### Key Concepts for Beginners

#### 1. **Providers** - Data Sources
```dart
// Simple value provider
final userIdProvider = Provider<String>((ref) => 'user123');

// State provider (mutable)
final counterProvider = StateProvider<int>((ref) => 0);

// Future provider (async data)
final userDataProvider = FutureProvider<User>((ref) async {
  return await fetchUserData();
});

// StateNotifier provider (complex state)
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController();
});
```

#### 2. **Consuming Providers** - Reading Data
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read and watch for changes
    final userId = ref.watch(userIdProvider);
    final counter = ref.watch(counterProvider);
    
    // Read once (no rebuild on change)
    final userData = ref.read(userDataProvider);
    
    return Text('User: $userId, Counter: $counter');
  }
}
```

#### 3. **Modifying State**
```dart
// In your widget
ElevatedButton(
  onPressed: () {
    // Update state provider
    ref.read(counterProvider.notifier).state++;
    
    // Call method on StateNotifier
    ref.read(chatControllerProvider.notifier).sendMessage('Hello');
  },
  child: Text('Send'),
)
```

---

## 🏗️ Project Architecture Overview

This sample custom chat UI follows a clean architecture pattern:

```
lib/
├── app/
│   └── app_widget.dart              # Main app with providers
├── core/
│   ├── config/
│   │   └── app_config.dart          # Configuration constants
│   └── services/
│       ├── chat_service.dart        # Abstract chat interface
│       ├── qiscus_chat_service.dart # Qiscus implementation
│       ├── message_service.dart     # Message handling
│       ├── image_upload_service.dart # Image upload logic
│       └── logger_service.dart      # Logging service
└── features/
    └── chat/
        ├── controllers/
        │   └── chat_controller.dart # Chat state management
        ├── pages/
        │   └── chat_screen.dart     # Chat screen page
        └── widgets/
            ├── custom_chat_room.dart # Main chat widget
            ├── image_attachment_widget.dart
            └── multi_image_message_widget.dart
```

---

## 🚀 Step-by-Step Implementation

### Step 1: Create Configuration

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String appId = 'your-qiscus-app-id';
  static const String userId = 'user123';
  static const String displayName = 'John Doe';
  
  static const Map<String, ChannelConfig> channels = {
    'general': ChannelConfig(
      id: 'general-channel-id',
      name: 'General Support',
    ),
    'technical': ChannelConfig(
      id: 'tech-channel-id', 
      name: 'Technical Support',
    ),
  };
}

class ChannelConfig {
  final String id;
  final String name;
  
  const ChannelConfig({
    required this.id,
    required this.name,
  });
}
```

### Step 3: Create Service Interfaces

```dart
// lib/core/services/chat_service.dart
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';

/// Abstract interface following Dependency Inversion Principle
abstract class IChatService {
  Future<void> initialize();
  Future<void> setUser({
    required String userId,
    required String displayName,
    String? avatarUrl,
  });
  Future<void> setChannelId(String channelId);
  Future<QChatRoom> initiateChat();
  void enableDebugMode(bool enabled);
}

/// Chat initialization states
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
}
```

---

## ⚡ Before Entering Chat Room

### Critical Setup Steps

#### 1. **Initialize Qiscus Multichannel**

```dart
// lib/core/services/qiscus_chat_service.dart
class QiscusChatService implements IChatService {
  final Ref _ref;
  final ILoggerService _logger;
  IQMultichannel? _provider;

  QiscusChatService({
    required Ref ref,
    required ILoggerService logger,
  }) : _ref = ref, _logger = logger;

  @override
  Future<void> initialize() async {
    try {
      _logger.debug('Initializing Qiscus chat service...');
      
      // 🔥 CRITICAL: Wait for provider to be ready
      await Future.delayed(const Duration(seconds: 2));
      
      _provider = _ref.read(QMultichannel.provider);
      
      if (_provider == null) {
        throw Exception('Failed to get QMultichannel provider');
      }
      
      _logger.debug('Qiscus provider initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize Qiscus', e);
      rethrow;
    }
  }

  @override
  Future<void> setUser({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    if (_provider == null) throw Exception('Provider not initialized');
    
    await _provider!.setUser(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    
    _logger.debug('User set: $userId - $displayName');
  }

  @override
  Future<void> setChannelId(String channelId) async {
    if (_provider == null) throw Exception('Provider not initialized');
    
    await _provider!.setChannelId(channelId);
    _logger.debug('Channel ID set: $channelId');
  }

  @override
  Future<QChatRoom> initiateChat() async {
    if (_provider == null) throw Exception('Provider not initialized');
    
    final chatRoom = await _provider!.initiateChat();
    _logger.debug('Chat initiated: ${chatRoom.id}');
    
    return chatRoom;
  }
}
```

#### 2. **Create Chat Controller with Riverpod**

```dart
// lib/features/chat/controllers/chat_controller.dart
class ChatController extends StateNotifier<ChatInitializationResult> {
  final IChatService _chatService;
  final ILoggerService _logger;

  ChatController({
    required IChatService chatService,
    required ILoggerService logger,
  }) : _chatService = chatService,
       _logger = logger,
       super(const ChatInitializationResult(state: ChatInitializationState.idle));

  /// 🔥 MAIN INITIALIZATION METHOD
  Future<void> initializeChat({String? channelKey}) async {
    try {
      _logger.debug('Starting chat initialization for channel: $channelKey');
      
      // 1. Set loading state
      state = const ChatInitializationResult(
        state: ChatInitializationState.initializing,
      );

      // 2. Initialize the chat service
      await _chatService.initialize();

      // 3. Enable debug mode for development
      _chatService.enableDebugMode(true);

      // 4. Set user information
      await _chatService.setUser(
        userId: AppConfig.userId,
        displayName: AppConfig.displayName,
        avatarUrl: 'https://ui-avatars.com/api/?name=${AppConfig.displayName}&background=random',
      );

      // 5. Set channel ID based on channel key
      String channelId;
      if (channelKey != null && AppConfig.channels.containsKey(channelKey)) {
        channelId = AppConfig.channels[channelKey]!.id;
      } else {
        channelId = AppConfig.channels.values.first.id;
      }
      
      await _chatService.setChannelId(channelId);

      // 6. Initiate chat room
      final chatRoom = await _chatService.initiateChat();

      // 7. Set success state
      state = ChatInitializationResult(
        state: ChatInitializationState.initialized,
        chatRoom: chatRoom,
        channelKey: channelKey,
      );

      _logger.info('Chat initialization completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Chat initialization failed', e, stackTrace);
      
      state = ChatInitializationResult(
        state: ChatInitializationState.error,
        error: e.toString(),
      );
    }
  }
}

// 🔥 PROVIDERS SETUP
final chatServiceProvider = Provider<IChatService>((ref) {
  final logger = LoggerService();
  return QiscusChatService(ref: ref, logger: logger);
});

final chatControllerProvider = StateNotifierProvider<ChatController, ChatInitializationResult>((ref) {
  final logger = LoggerService();
  final chatService = ref.watch(chatServiceProvider);
  
  return ChatController(
    chatService: chatService,
    logger: logger,
  );
});
```

#### 3. **Setup Your App Widget**

```dart
// lib/app/app_widget.dart
class AppWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QMultichannel(
      appId: AppConfig.appId,
      child: HomePage(),
    );
  }
}
```

---

## 🎨 Building the Custom Chat Room Widget

### Understanding the Widget Structure

```dart
// lib/features/chat/widgets/custom_chat_room.dart
class CustomChatRoom extends ConsumerStatefulWidget {
  final QChatRoom chatRoom;

  const CustomChatRoom({
    super.key,
    required this.chatRoom,
  });

  @override
  ConsumerState<CustomChatRoom> createState() => _CustomChatRoomState();
}
```

### Key Components Breakdown

#### 1. **State Management with Riverpod**

```dart
class _CustomChatRoomState extends ConsumerState<CustomChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ILoggerService _logger = LoggerService();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    // 🔥 Watch providers for reactive updates
    final messages = ref.watch(messagesNotifierProvider).reversed.toList();
    final room = ref.watch(roomProvider.select((v) => v.valueOrNull?.room));
    
    // Show loading if no data yet
    if (messages.isEmpty && room == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty && room != null
              ? _buildEmptyState()
              : _buildMessagesList(messages),
        ),
        _buildMessageInput(),
      ],
    );
  }
}
```

#### 2. **Message Sending Logic**

```dart
Future<void> _sendMessage() async {
  final messageText = _messageController.text.trim();
  final hasText = messageText.isNotEmpty;
  final hasImages = _selectedImages.isNotEmpty;
  
  if (!hasText && !hasImages) return;
  if (_isUploading) {
    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please wait, images are still uploading...'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // Clear input immediately for better UX
  _messageController.clear();
  final imagesToSend = List<File>.from(_selectedImages);
  setState(() {
    _selectedImages.clear();
  });

  try {
    // Send text message if available
    if (hasText) {
      final textMessage = QMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        chatRoomId: widget.chatRoom.id,
        uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
        text: messageText,
        type: QMessageType.text,
        timestamp: DateTime.now(),
        status: QMessageStatus.sending,
        previousMessageId: 0,
        extras: {},
        payload: {},
        sender: QUser(
          id: AppConfig.userId,
          name: AppConfig.displayName,
          avatarUrl: null,
        ),
      );
      
      // 🔥 Use Riverpod to send message
      await ref.read(messagesNotifierProvider.notifier).sendMessage(textMessage);
      _logger.debug('Text message sent successfully');
    }
    
    // Upload and send images if available
    if (imagesToSend.isNotEmpty) {
      await _uploadAndSendImages(imagesToSend);
    }
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
  } catch (e) {
    _logger.error('Failed to send message', e);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
```

#### 3. **Image Upload with Progress**

```dart
Future<void> _uploadAndSendImages(List<File> imageFiles) async {
  if (imageFiles.isEmpty) return;
  
  setState(() {
    _isUploading = true;
  });
  
  try {
    // Show upload progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('Uploading images...'),
          ],
        ),
        duration: Duration(minutes: 5),
      ),
    );
    
    // 🔥 Get service from Riverpod provider
    final imageUploadService = ref.read(imageUploadServiceProvider);
    
    // Upload with progress callback
    final uploadedUrls = await imageUploadService.uploadMultipleImages(
      imageFiles,
      onProgress: (current, total, progress) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploading $current of $total: ${(progress * 100).toInt()}%'),
            duration: const Duration(milliseconds: 300),
          ),
        );
      },
    );
    
    setState(() {
      _isUploading = false;
    });
    
    if (uploadedUrls.isEmpty) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload images')),
      );
      return;
    }
    
    // 🔥 Get message service from provider
    final messageService = ref.read(messageServiceProvider);
    
    // Handle single vs multiple images
    if (uploadedUrls.length > 1) {
      // Multi-image message
      final message = messageService.generateMultiImageMessage(
        chatRoomId: widget.chatRoom.id,
        imageUrls: uploadedUrls,
        imageFiles: imageFiles,
      );
      await messageService.sendMessage(message);
    } else if (uploadedUrls.isNotEmpty) {
      // Single image message
      final imageFile = imageFiles.first;
      final message = messageService.generateImageMessage(
        chatRoomId: widget.chatRoom.id,
        imageUrl: uploadedUrls.first,
        filePath: imageFile.path,
        fileSize: imageFile.lengthSync(),
      );
      await messageService.sendMessage(message);
    }
    
    // Success feedback
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${uploadedUrls.length} image(s) sent')),
    );
    
  } catch (e) {
    _logger.error('Failed to upload images', e);
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
    setState(() {
      _isUploading = false;
    });
  }
}
```

#### 4. **Message Bubble Rendering**

```dart
Widget _buildMessageBubble(QMessage message) {
  // 🔥 Use Riverpod to get account info
  final accountId = ref.watch(accountProvider.select((v) => v.whenData((value) => value.id)));
  
  return accountId.when(
    data: (accountId) {
      final isMe = message.sender.id == accountId;
      return _buildMessageWidget(message, isMe);
    },
    loading: () => _buildChatBubble(message, false),
    error: (e, _) => _buildChatBubble(message, false),
  );
}

Widget _buildMessageWidget(QMessage message, bool isMe) {
  switch (message.type) {
    case QMessageType.text:
      return _buildChatBubble(message, isMe);
    case QMessageType.attachment:
      return _buildImageBubble(message, isMe);
    case QMessageType.custom:
      // Handle custom multi-image messages
      if (message.payload?['type'] == 'multi_images') {
        return _buildMultiImageBubble(message, isMe);
      }
      return _buildChatBubble(message, isMe);
    default:
      return _buildChatBubble(message, isMe);
  }
}
```

---

## 🔧 Advanced Features

### 1. **Multi-Image Message Support**

```dart
// lib/features/chat/widgets/multi_image_message_widget.dart
class MultiImageMessageWidget extends StatelessWidget {
  final QMessage message;

  const MultiImageMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final images = _extractImages();
    
    if (images.isEmpty) {
      return const Text('No images to display');
    }

    return _buildImageGrid(images);
  }

  List<String> _extractImages() {
    try {
      final payload = message.payload;
      if (payload != null && payload['images'] is List) {
        return List<String>.from(payload['images']);
      }
    } catch (e) {
      print('Error extracting images: $e');
    }
    return [];
  }

  Widget _buildImageGrid(List<String> images) {
    if (images.length == 1) {
      return _buildSingleImage(images.first);
    } else if (images.length == 2) {
      return _buildTwoImages(images);
    } else if (images.length == 3) {
      return _buildThreeImages(images);
    } else {
      return _buildFourPlusImages(images);
    }
  }

  // Implementation for different layouts...
}
```

### 2. **Image Upload Service**

```dart
// lib/core/services/image_upload_service.dart
abstract class IImageUploadService {
  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    Function(int current, int total, double progress)? onProgress,
  });
}

class ImageUploadService implements IImageUploadService {
  final ILoggerService _logger;

  ImageUploadService({required ILoggerService logger}) : _logger = logger;

  @override
  Future<List<String>> uploadMultipleImages(
    List<File> files, {
    Function(int current, int total, double progress)? onProgress,
  }) async {
    final uploadedUrls = <String>[];
    
    for (int i = 0; i < files.length; i++) {
      try {
        onProgress?.call(i + 1, files.length, 0.0);
        
        // Simulate upload progress
        for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
          await Future.delayed(const Duration(milliseconds: 100));
          onProgress?.call(i + 1, files.length, progress);
        }
        
        // Actual upload logic here
        final url = await _uploadSingleFile(files[i]);
        uploadedUrls.add(url);
        
      } catch (e) {
        _logger.error('Failed to upload image ${i + 1}', e);
      }
    }
    
    return uploadedUrls;
  }

  Future<String> _uploadSingleFile(File file) async {
    // Implement your actual upload logic
    // Return the uploaded image URL
    return 'https://example.com/uploaded-image.jpg';
  }
}

// 🔥 Provider for the service
final imageUploadServiceProvider = Provider<IImageUploadService>((ref) {
  final logger = LoggerService();
  return ImageUploadService(logger: logger);
});
```

---

## 🧪 Testing & Debugging

### 1. **Debug Mode Setup**

```dart
// Enable debug logging
final logger = LoggerService();
logger.debug('Message sent: ${message.text}');
logger.error('Upload failed', error, stackTrace);
```

### 2. **Provider Testing**

```dart
// Test your providers
void main() {
  testWidgets('Chat controller initializes correctly', (tester) async {
    final container = ProviderContainer();
    
    final controller = container.read(chatControllerProvider.notifier);
    await controller.initializeChat();
    
    final state = container.read(chatControllerProvider);
    expect(state.state, ChatInitializationState.initialized);
  });
}
```

### 3. **Common Issues & Solutions**


#### Issue: State not updating
```dart
// ❌ Wrong: Using read() in build method
final messages = ref.read(messagesProvider);

// ✅ Correct: Using watch() for reactive updates
final messages = ref.watch(messagesProvider);
```

---

## 🎯 Best Practices

### 1. **Riverpod Best Practices**

```dart
// ✅ Use specific selectors to avoid unnecessary rebuilds
final userName = ref.watch(userProvider.select((user) => user.name));

// ✅ Dispose controllers properly
@override
void dispose() {
  _messageController.dispose();
  _scrollController.dispose();
  super.dispose();
}

// ✅ Handle loading and error states
final asyncValue = ref.watch(messagesProvider);
return asyncValue.when(
  data: (messages) => MessagesList(messages),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

### 2. **Error Handling**

```dart
try {
  await _sendMessage();
} catch (e) {
  _logger.error('Send message failed', e);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### 3. **Performance Optimization**

```dart
// ✅ Use ListView.builder for large lists
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(messages[index]),
);

// ✅ Implement proper image caching
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
);
```

---

## 🚀 Quick Start Checklist

### Before Entering Chat Room:
- [ ] ✅ Qiscus app ID configured
- [ ] ✅ User information set (userId, displayName)
- [ ] ✅ Channel ID configured
- [ ] ✅ Chat service initialized
- [ ] ✅ Providers properly set up

### Custom UI Implementation:
- [ ] ✅ `ConsumerStatefulWidget` used for chat room
- [ ] ✅ Messages watched with `ref.watch()`
- [ ] ✅ Message sending uses `ref.read().notifier`
- [ ] ✅ Image upload service integrated
- [ ] ✅ Error handling implemented
- [ ] ✅ Loading states handled
- [ ] ✅ UI feedback for user actions

### Testing:
- [ ] ✅ Text messages send correctly
- [ ] ✅ Image upload works with progress
- [ ] ✅ Multi-image messages display properly
- [ ] ✅ Error states handled gracefully
- [ ] ✅ Loading indicators work
- [ ] ✅ Auto-scroll functions correctly

---

## 🎉 Conclusion

You now have a comprehensive understanding of building custom chat UI with Qiscus Multichannel and Riverpod! This tutorial covers:

- **Riverpod fundamentals** for beginners
- **Complete setup process** before entering chat
- **Custom UI implementation** with proper state management
- **Advanced features** like multi-image support
- **Best practices** for maintainable code

Remember: The key to success with Riverpod is understanding the reactive nature of providers and properly managing state updates. Start simple, then gradually add complexity as you become more comfortable with the patterns.

Happy coding! 🚀
