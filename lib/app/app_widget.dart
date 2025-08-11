import 'package:flutter/material.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../core/config/app_config.dart';
import '../features/chat/pages/home_page.dart';

/// App widget following Single Responsibility Principle
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {

  @override
  Widget build(BuildContext context) {
    return QMultichannelProvider(
      appId: AppConfig.qiscusAppId,
      hideEventUI: true,
      builder: (context) {
        return MaterialApp(
          title: AppConfig.appTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomePage(title: AppConfig.appTitle),
        );
      },
    );
  }
}
