import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/db/local_database.dart';

/// The traveller's advisory alert choice. Off until they turn it on.
class AlertPrefs {
  const AlertPrefs({
    this.enabled = false,
    this.allPorts = true,
    this.portIds = const {},
    this.subscribedTopics = const {},
  });

  final bool enabled;

  /// "All of Romblon", or only [portIds].
  final bool allPorts;
  final Set<String> portIds;

  /// Topics this device is currently subscribed to (to undo them later).
  final Set<String> subscribedTopics;

  AlertPrefs copyWith({
    bool? enabled,
    bool? allPorts,
    Set<String>? portIds,
    Set<String>? subscribedTopics,
  }) => AlertPrefs(
    enabled: enabled ?? this.enabled,
    allPorts: allPorts ?? this.allPorts,
    portIds: portIds ?? this.portIds,
    subscribedTopics: subscribedTopics ?? this.subscribedTopics,
  );

  Json toJson() => {
    'enabled': enabled,
    'allPorts': allPorts,
    'portIds': portIds.toList()..sort(),
    'subscribedTopics': subscribedTopics.toList()..sort(),
  };

  factory AlertPrefs.fromJson(Json json) => AlertPrefs(
    enabled: json.opt<bool>('enabled') ?? false,
    allPorts: json.opt<bool>('allPorts') ?? true,
    portIds: json.strings('portIds').toSet(),
    subscribedTopics: json.strings('subscribedTopics').toSet(),
  );
}

abstract interface class AlertPrefsRepository {
  Future<AlertPrefs> load();
  Future<void> save(AlertPrefs prefs);
}

class SqliteAlertPrefsRepository implements AlertPrefsRepository {
  const SqliteAlertPrefsRepository(this.database);

  static const _key = 'alert_prefs';
  final LocalDatabase database;

  @override
  Future<AlertPrefs> load() async {
    final raw = await database.getValue(_key);
    return raw == null
        ? const AlertPrefs()
        : AlertPrefs.fromJson(jsonDecode(raw) as Json);
  }

  @override
  Future<void> save(AlertPrefs prefs) =>
      database.setValue(_key, jsonEncode(prefs.toJson()));
}

class MemoryAlertPrefsRepository implements AlertPrefsRepository {
  AlertPrefs prefs = const AlertPrefs();

  @override
  Future<AlertPrefs> load() async => prefs;

  @override
  Future<void> save(AlertPrefs prefs) async => this.prefs = prefs;
}

/// Push notifications for caution and suspension advisories.
abstract interface class AlertsService {
  /// Asks for the notification permission (Android 13+). False if refused.
  Future<bool> requestPermission();
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);

  /// The advisory the app was opened from, when launched by tapping an alert.
  Future<String?> initialAdvisoryId();

  /// Advisory ids of alerts tapped while the app was running.
  Stream<String> get openedAdvisoryIds;

  /// Fires when an alert arrives while the app is open (to sync at once).
  Stream<void> get foregroundAlerts;
}

class FcmAlertsService implements AlertsService {
  FcmAlertsService(this.messaging);

  final FirebaseMessaging messaging;

  static String? _advisoryId(RemoteMessage m) =>
      m.data['advisoryId'] as String?;

  @override
  Future<bool> requestPermission() async {
    final settings = await messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> subscribe(String topic) => messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribe(String topic) =>
      messaging.unsubscribeFromTopic(topic);

  @override
  Future<String?> initialAdvisoryId() async {
    final message = await messaging.getInitialMessage();
    return message == null ? null : _advisoryId(message);
  }

  @override
  Stream<String> get openedAdvisoryIds => FirebaseMessaging.onMessageOpenedApp
      .map(_advisoryId)
      .where((id) => id != null)
      .cast<String>();

  @override
  Stream<void> get foregroundAlerts => FirebaseMessaging.onMessage;
}
