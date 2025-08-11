import 'package:flutter/material.dart';

/// Loading widget following Single Responsibility Principle
class ChatLoadingWidget extends StatelessWidget {
  final String title;

  const ChatLoadingWidget({
    super.key,
    this.title = 'Qiscus Chat',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
