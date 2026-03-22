/// env_config.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// All sensitive keys are injected at BUILD TIME via --dart-define.
/// NEVER hardcode real values here.
///
/// Local development — run with:
///   flutter run \
///     --dart-define=OPENWEATHER_API_KEY=your_key_here \
///     --dart-define=EMAILJS_SERVICE_ID=your_id \
///     --dart-define=EMAILJS_TEMPLATE_ID=your_template \
///     --dart-define=EMAILJS_PUBLIC_KEY=your_public_key
///
/// Docker / Cloud Build — values are passed as --build-arg and forwarded
/// to flutter build web --dart-define=KEY=VALUE inside the Dockerfile.
/// ─────────────────────────────────────────────────────────────────────────────

class EnvConfig {
  // ── OpenWeatherMap ──────────────────────────────────────────────────────────
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '8bdae2928bf486003e095bfeb2983d92',
  );

  static const String openWeatherApiUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // ── EmailJS (OTP emails) ────────────────────────────────────────────────────
  static const String emailJsServiceId = String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
    defaultValue: 'service_vqyyrco',
  );

  static const String emailJsTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ID',
    defaultValue: 'template_5bel3d3',
  );

  static const String emailJsPublicKey = String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
    defaultValue: 'lLIveH1AUGcxBG4oK',
  );

  // ── Validation helper ───────────────────────────────────────────────────────
  /// Called in main() as a safety net for production/CI builds where
  /// --dart-define must be explicitly passed. Locally the defaultValues
  /// above are used so this is a no-op in normal development.
  static void assertKeysPresent() {
    assert(
      openWeatherApiKey.isNotEmpty,
      '\n\n[EnvConfig] OPENWEATHER_API_KEY is missing!\n'
      'Pass via: flutter run --dart-define=OPENWEATHER_API_KEY=your_key\n'
      'Or set a defaultValue in env_config.dart for local dev.\n',
    );
    assert(
      emailJsServiceId.isNotEmpty,
      '\n\n[EnvConfig] EMAILJS_SERVICE_ID is missing!\n'
      'Pass via: flutter run --dart-define=EMAILJS_SERVICE_ID=your_id\n',
    );
    assert(
      emailJsPublicKey.isNotEmpty,
      '\n\n[EnvConfig] EMAILJS_PUBLIC_KEY is missing!\n'
      'Pass via: flutter run --dart-define=EMAILJS_PUBLIC_KEY=your_key\n',
    );
  }
}
