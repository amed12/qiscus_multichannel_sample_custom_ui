import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../config/app_config.dart';
import 'logger_service.dart';

/// Firebase Remote Config service following Single Responsibility Principle
/// Responsible for managing remote configuration values
abstract class IFirebaseConfigService {
  Future<void> initialize();
  Future<void> fetchAndActivate();
  String getQiscusAppId();
  String getKonsultasiChannelId();
  String getBantuanChannelId();
  String getQiscusSdkBaseUrl();
  String getQiscusBaseUrl();
  String getAppTitle();
  bool getEnableDebugMode();
  int getFetchTimeoutMinutes();
  int getMinimumFetchIntervalHours();
  Map<String, ChannelConfig> getChannelConfigs();
}

class FirebaseConfigService implements IFirebaseConfigService {
  final ILoggerService _logger;
  late final FirebaseRemoteConfig _remoteConfig;
  
  // Remote config keys
  static const String _qiscusAppIdKey = 'qiscus_app_id';
  static const String _konsultasiChannelIdKey = 'konsultasi_channel_id';
  static const String _bantuanChannelIdKey = 'bantuan_channel_id';
  static const String _qiscusSdkBaseUrlKey = 'qiscus_sdk_base_url';
  static const String _qiscusBaseUrlKey = 'qiscus_base_url';
  static const String _appTitleKey = 'app_title';
  static const String _enableDebugModeKey = 'enable_debug_mode';
  static const String _fetchTimeoutMinutesKey = 'fetch_timeout_minutes';
  static const String _minimumFetchIntervalHoursKey = 'minimum_fetch_interval_hours';
  
  FirebaseConfigService({
    required ILoggerService logger,
  }) : _logger = logger;

  @override
  Future<void> initialize() async {
    try {
      _logger.debug('Initializing Firebase Remote Config...');
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set configuration settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: Duration(minutes: int.parse(AppConfig.fetchTimeoutMinutes)),
          minimumFetchInterval: Duration(hours: int.parse(AppConfig.minimumFetchIntervalHours)),
        ),
      );
      
      // Set default values
      await _remoteConfig.setDefaults({
        _qiscusAppIdKey: AppConfig.qiscusAppId,
        _konsultasiChannelIdKey: AppConfig.channels['konsultasi']?.id ?? 'YOUR_CHANNEL_ID',
        _bantuanChannelIdKey: AppConfig.channels['bantuan']?.id ?? 'YOUR_CHANNEL_ID',
        _qiscusSdkBaseUrlKey: AppConfig.sdkBaseUrl,
        _qiscusBaseUrlKey: AppConfig.baseUrl,
        _appTitleKey: AppConfig.appTitle,
        _enableDebugModeKey: AppConfig.enableDebugMode.toString(),
        _fetchTimeoutMinutesKey: AppConfig.fetchTimeoutMinutes,
        _minimumFetchIntervalHoursKey: AppConfig.minimumFetchIntervalHours,
      });
      
      _logger.info('Firebase Remote Config initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Firebase Remote Config', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      _logger.debug('Fetching and activating remote config...');
      
      final activated = await _remoteConfig.fetchAndActivate();
      
      if (activated) {
        _logger.info('Remote config fetched and activated successfully');
        _logCurrentValues();
      } else {
        _logger.info('Remote config fetched but not activated (no changes)');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch and activate remote config', e, stackTrace);
      // Don't rethrow - use default values if remote config fails
    }
  }

  @override
  String getQiscusAppId() {
    final value = _remoteConfig.getString(_qiscusAppIdKey);
    _logger.debug('Retrieved Qiscus App ID: $value');
    return value;
  }

  @override
  String getKonsultasiChannelId() {
    final value = _remoteConfig.getString(_konsultasiChannelIdKey);
    _logger.debug('Retrieved Konsultasi Channel ID: $value');
    return value;
  }

  @override
  String getBantuanChannelId() {
    final value = _remoteConfig.getString(_bantuanChannelIdKey);
    _logger.debug('Retrieved Bantuan Channel ID: $value');
    return value;
  }
  
  @override
  String getQiscusSdkBaseUrl() {
    final value = _remoteConfig.getString(_qiscusSdkBaseUrlKey);
    _logger.debug('Retrieved Qiscus SDK Base URL: $value');
    return value;
  }
  
  @override
  String getQiscusBaseUrl() {
    final value = _remoteConfig.getString(_qiscusBaseUrlKey);
    _logger.debug('Retrieved Qiscus Base URL: $value');
    return value;
  }
  
  @override
  String getAppTitle() {
    final value = _remoteConfig.getString(_appTitleKey);
    _logger.debug('Retrieved App Title: $value');
    return value;
  }
  
  @override
  bool getEnableDebugMode() {
    final value = _remoteConfig.getBool(_enableDebugModeKey);
    _logger.debug('Retrieved Enable Debug Mode: $value');
    return value;
  }
  
  @override
  int getFetchTimeoutMinutes() {
    final value = _remoteConfig.getInt(_fetchTimeoutMinutesKey);
    _logger.debug('Retrieved Fetch Timeout Minutes: $value');
    return value;
  }
  
  @override
  int getMinimumFetchIntervalHours() {
    final value = _remoteConfig.getInt(_minimumFetchIntervalHoursKey);
    _logger.debug('Retrieved Minimum Fetch Interval Hours: $value');
    return value;
  }

  @override
  Map<String, ChannelConfig> getChannelConfigs() {
    return {
      'konsultasi': ChannelConfig(
        id: getKonsultasiChannelId(),
        name: 'Konsultasi',
        description: 'Konsultasi dan pertanyaan umum',
        icon: '💬',
      ),
      'bantuan': ChannelConfig(
        id: getBantuanChannelId(),
        name: 'Bantuan',
        description: 'Bantuan teknis dan dukungan',
        icon: '🆘',
      ),
    };
  }

  void _logCurrentValues() {
    _logger.debug('Current Remote Config Values:');
    _logger.debug('- Qiscus App ID: ${getQiscusAppId()}');
    _logger.debug('- Konsultasi Channel ID: ${getKonsultasiChannelId()}');
    _logger.debug('- Bantuan Channel ID: ${getBantuanChannelId()}');
    _logger.debug('- Qiscus SDK Base URL: ${getQiscusSdkBaseUrl()}');
    _logger.debug('- Qiscus Base URL: ${getQiscusBaseUrl()}');
    _logger.debug('- App Title: ${getAppTitle()}');
    _logger.debug('- Enable Debug Mode: ${getEnableDebugMode()}');
    _logger.debug('- Fetch Timeout Minutes: ${getFetchTimeoutMinutes()}');
    _logger.debug('- Minimum Fetch Interval Hours: ${getMinimumFetchIntervalHours()}');
  }
}
