import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderContainer(
      overrides: [
        appIdProvider.overrideWith((ref) => AppConfig.qiscusAppId),
        sdkBaseUrlProvider.overrideWith((ref) => AppConfig.sdkBaseUrl),
        baseUrlProvider.overrideWith((ref) => AppConfig.baseUrl),
        channelIdConfigProvider.overrideWith((ref) => AppConfig.channelId),
      ],
    );
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      parent: _container,
      child: QMultichannelProvider(
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
      ),
    );
  }
}
