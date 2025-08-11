import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiscus_multichannel_widget/qiscus_multichannel_widget.dart';
import '../core/config/app_config.dart';
import '../core/providers/firebase_config_provider.dart';
import '../features/chat/pages/home_page.dart';

/// Root application widget following Single Responsibility Principle
/// Responsible for setting up the main app structure and providers
class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfigAsync = ref.watch(appConfigProvider);
    
    return appConfigAsync.when(
      data: (appConfig) => QMultichannelProvider(
        appId: appConfig.qiscusAppId,
        hideEventUI: true,
        builder: (context) {
          return MaterialApp(
            title: AppConfig.appTitle,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: HomePage(
              title: AppConfig.appTitle,
              remoteChannels: appConfig.channels,
            ),
          );
        },
      ),
      loading: () => MaterialApp(
        title: AppConfig.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading configuration...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) {
        // Fallback to default configuration if remote config fails
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
      },
    );
  }
}
