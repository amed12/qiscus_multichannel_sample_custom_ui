import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';

/// Provider to store the message being replied to
/// EXACTLY like SDK pattern from replied_message_provider.dart
final repliedMessageProvider = StateProvider<QMessage?>((ref) => null);
