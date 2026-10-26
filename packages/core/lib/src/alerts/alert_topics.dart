/// Push-alert topic names, shared by the app (subscribing) and mirrored in
/// `firebase/functions/topics.js` (sending). Keep the two in sync.
///
/// - "All of Romblon" subscribers get `adv_all_<lang>` only.
/// - Port subscribers get `adv_port_<portId>_<lang>` for each chosen port,
///   plus `adv_general_<lang>` for advisories that name no port.
///
/// Alerts are sent in English or Tagalog; other languages get English.
library;

String alertLanguage(String? languageCode) =>
    languageCode == 'fil' ? 'fil' : 'en';

/// FCM topic names allow only `[a-zA-Z0-9-_.~%]`.
String topicSafe(String id) =>
    id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '-');

Set<String> alertTopics({
  required bool allPorts,
  required Set<String> portIds,
  required String? languageCode,
}) {
  final lang = alertLanguage(languageCode);
  if (allPorts) return {'adv_all_$lang'};
  if (portIds.isEmpty) return const {};
  return {
    'adv_general_$lang',
    for (final id in portIds) 'adv_port_${topicSafe(id)}_$lang',
  };
}
