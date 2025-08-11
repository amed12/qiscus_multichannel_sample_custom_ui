import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_config_service.dart';
import '../services/logger_service.dart';
import '../config/app_config.dart';

/// Provider for Firebase Remote Config service
final firebaseConfigServiceProvider = Provider<IFirebaseConfigService>((ref) {
  final logger = LoggerService();
  return FirebaseConfigService(logger: logger);
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
  );
});

/// Data class for app configuration
class AppConfigData {
  final String qiscusAppId;
  final Map<String, ChannelConfig> channels;
  
  const AppConfigData({
    required this.qiscusAppId,
    required this.channels,
  });
}
