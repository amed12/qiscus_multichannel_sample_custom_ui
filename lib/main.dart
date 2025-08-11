import 'package:flutter/material.dart';
import 'app/app_widget.dart';

/// Main entry point following SOLID principles
/// - Single Responsibility: Only responsible for app initialization
/// - Open/Closed: Can be extended without modification
/// - Liskov Substitution: Follows Flutter's main function contract
/// - Interface Segregation: Uses minimal required interfaces
/// - Dependency Inversion: Depends on abstractions (Flutter framework)
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppWidget());
}
