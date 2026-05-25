class AppConfig {
  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _developmentBaseUrl = String.fromEnvironment(
    'DEV_BASE_URL',
    defaultValue: 'https://api.iot.memcoin.com',
  );

  static const String _productionBaseUrl = String.fromEnvironment(
    'PROD_BASE_URL',
    defaultValue: 'https://api.iot.memcoin.com',
  );

  static const String defaultMachineId = String.fromEnvironment(
    'MACHINE_ID',
    defaultValue: '2',
  );

  static bool get isProduction {
    final normalized = _appEnv.trim().toLowerCase();

    return normalized == 'prod' ||
        normalized == 'production';
  }

  static String get baseUrl {
    final configuredBaseUrl =
        _baseUrlOverride.trim().isNotEmpty
            ? _baseUrlOverride
            : (isProduction
                ? _productionBaseUrl
                : _developmentBaseUrl);

    return _normalizeBaseUrl(configuredBaseUrl);
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}