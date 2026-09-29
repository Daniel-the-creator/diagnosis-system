/// Environment modes for development, staging and production builds.
enum Environment {
  development,
  staging,
  production,
}

/// Central application environment and runtime configuration manager.
class AppConfig {
  final Environment environment;
  final String appName;
  final bool enableDebugLogging;
  final bool enableAnalytics;
  final bool useEmulators;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.enableDebugLogging,
    required this.enableAnalytics,
    required this.useEmulators,
  });

  bool get isProduction => environment == Environment.production;
  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;

  static late AppConfig _current;
  static AppConfig get current => _current;

  static void initialize({
    Environment environment = Environment.production,
    bool? useEmulators,
  }) {
    switch (environment) {
      case Environment.development:
        _current = AppConfig(
          environment: Environment.development,
          appName: 'MediFlow HMS (Dev)',
          enableDebugLogging: true,
          enableAnalytics: false,
          useEmulators: useEmulators ?? false,
        );
        break;
      case Environment.staging:
        _current = AppConfig(
          environment: Environment.staging,
          appName: 'MediFlow HMS (Staging)',
          enableDebugLogging: true,
          enableAnalytics: true,
          useEmulators: useEmulators ?? false,
        );
        break;
      case Environment.production:
        _current = AppConfig(
          environment: Environment.production,
          appName: 'MediFlow HMS',
          enableDebugLogging: false,
          enableAnalytics: true,
          useEmulators: false,
        );
        break;
    }
  }
}
