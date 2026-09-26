// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): configuración centralizada de monetización.
class AdsConfig {
  const AdsConfig._();

  /// Ejemplo de compilación web:
  /// flutter build web --dart-define=ADSENSE_PUBLISHER_ID=ca-pub-1234567890123456
  static const publisherId = String.fromEnvironment(
    'ADSENSE_PUBLISHER_ID',
    defaultValue: '',
  );

  static bool get enabled => publisherId.startsWith('ca-pub-');
}
