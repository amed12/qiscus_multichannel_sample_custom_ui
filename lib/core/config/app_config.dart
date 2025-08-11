/// Application configuration following Single Responsibility Principle
class AppConfig {
  static const String userId = 'sample-user-id';
  static const String displayName = 'Qiscus User Test';
  static const String qiscusAppId = 'YOUR_APP_ID';
  static const String sdkBaseUrl = 'https://api3.qiscus.com';
  static const String baseUrl = 'https://multichannel.qiscus.com';
  static const String appTitle = 'Multi-Channel Chat Demo';
  static const bool enableDebugMode = true;
  static const String fetchTimeoutMinutes = '1';
  static const String minimumFetchIntervalHours = '1';
  
  // Channel configurations
  static const Map<String, ChannelConfig> channels = {
    'konsultasi': ChannelConfig(
      id: 'YOUR_CHANNEL_ID',
      name: 'Konsultasi',
      description: 'Konsultasi dan pertanyaan umum',
      icon: '💬',
    ),
    'bantuan': ChannelConfig(
      id: 'YOUR_CHANNEL_ID', 
      name: 'Bantuan',
      description: 'Bantuan teknis dan dukungan',
      icon: '🆘',
    ),
  };
}

/// Channel configuration model
class ChannelConfig {
  final String id;
  final String name;
  final String description;
  final String icon;
  
  const ChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
