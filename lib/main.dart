import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/app_widget.dart';
import 'core/services/firebase_config_service.dart';
import 'core/services/logger_service.dart';

/// Main entry point following SOLID principles
/// - Single Responsibility: Entry point for the application
/// - Open/Closed: Open for extension through app configuration
/// - Liskov Substitution: Can be substituted with different app implementations
/// - Interface Segregation: Minimal interface for app startup
/// - Dependency Inversion: Depends on abstractions (Flutter framework)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = LoggerService();
  
  try {
    // Initialize Firebase
    logger.info('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Remote Config
    logger.info('Initializing Firebase Remote Config...');
    final configService = FirebaseConfigService(logger: logger);
    await configService.initialize();
    
    logger.info('App initialization completed successfully');
    
    runApp(
      ProviderScope(
        child: const AppWidget(),
      ),
    );
  } catch (e, stackTrace) {
    logger.error('Failed to initialize app', e, stackTrace);
    
    // Run app with default configuration if Firebase fails
    logger.info('Running app with default configuration');
    runApp(
      ProviderScope(
        child: const AppWidget(),
      ),
    );
  }
}
