import 'package:flutter/material.dart';

/// Helper class for testing image upload functionality
class ImageTestHelper {
  /// Creates test image files for upload testing
  /// Returns a list of File objects that can be used for testing
  
  
  /// Simulates network conditions for testing
  /// Use this to test upload under different network conditions
  static Future<void> simulateNetworkCondition({
    required BuildContext context,
    NetworkCondition condition = NetworkCondition.good,
    Duration duration = const Duration(seconds: 2),
  }) async {
    String message;
    
    switch (condition) {
      case NetworkCondition.good:
        message = 'Testing with good network connection';
        break;
      case NetworkCondition.poor:
        message = 'Testing with poor network connection';
        // Could add artificial delay here
        break;
      case NetworkCondition.offline:
        message = 'Testing with offline condition';
        // Could throw exception here to simulate offline
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    
    await Future.delayed(duration);
  }
  
  /// Logs test results
  static void logTestResult({
    required String testName,
    required bool success,
    String? message,
  }) {
    final result = success ? 'PASSED' : 'FAILED';
    debugPrint('TEST [$testName]: $result ${message != null ? '- $message' : ''}');
  }
}

/// Enum representing different network conditions for testing
enum NetworkCondition {
  good,
  poor,
  offline,
}
