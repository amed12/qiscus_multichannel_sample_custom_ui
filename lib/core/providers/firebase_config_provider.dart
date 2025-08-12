import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_config_service.dart';
import '../services/logger_service.dart';
import '../config/app_config.dart';

/// Provider for Firebase Remote Config service
final firebaseConfigServiceProvider = Provider<IFirebaseConfigService>((ref) {
  final logger = LoggerService();
  return FirebaseConfigService(FirebaseRemoteConfig.instance, logger: logger);
});

/// Provider for remote Qiscus App ID
final remoteQiscusAppIdProvider = FutureProvider<String>((ref) async {
  final configService = ref.watch(firebaseConfigServiceProvider);
  await configService.fetchAndActivate();
  return configService.getQiscusAppId();
});

/// Provider for remote channel configurations
final remoteChannelConfigsProvider = FutureProvider<Map<String, ChannelConfig>>((ref) async {
  final configService = ref.watch(firebaseConfigServiceProvider);
  await configService.fetchAndActivate();
  return configService.getChannelConfigs();
});

/// Provider for combined app configuration (local + remote)
final appConfigProvider = FutureProvider<AppConfigData>((ref) async {
  final configService = ref.watch(firebaseConfigServiceProvider);
  await configService.fetchAndActivate();
  
  return AppConfigData(
    qiscusAppId: configService.getQiscusAppId(),
    channels: configService.getChannelConfigs(),
    sdkBaseUrl: configService.getQiscusSdkBaseUrl(),
    baseUrl: configService.getQiscusBaseUrl(),
    appTitle: configService.getAppTitle(),
    enableDebugMode: configService.getEnableDebugMode(),
    fetchTimeoutMinutes: configService.getFetchTimeoutMinutes(),
    minimumFetchIntervalHours: configService.getMinimumFetchIntervalHours(),
  );
});

/// Data class for app configuration
class AppConfigData {
  final String qiscusAppId;
  final Map<String, ChannelConfig> channels;
  final String sdkBaseUrl;
  final String baseUrl;
  final String appTitle;
  final bool enableDebugMode;
  final int fetchTimeoutMinutes;
  final int minimumFetchIntervalHours;
  
  const AppConfigData({
    required this.qiscusAppId,
    required this.channels,
    required this.sdkBaseUrl,
    required this.baseUrl,
    required this.appTitle,
    required this.enableDebugMode,
    required this.fetchTimeoutMinutes,
    required this.minimumFetchIntervalHours,
  });
}
