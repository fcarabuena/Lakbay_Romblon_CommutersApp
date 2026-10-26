import 'dart:convert';

import 'package:lakbay_core/lakbay_core.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/local_database.dart';

/// A trip the traveller saved. The plan itself is recomputed from [request]
/// when opened, so saved trips pick up corrected fares automatically.
class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.name,
    required this.request,
    required this.planId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final TripRequest request;
  final String planId;
  final DateTime createdAt;
}

abstract interface class SavedTripsRepository {
  Future<List<SavedTrip>> all();
  Future<void> save(SavedTrip trip);
  Future<void> delete(String id);
}

abstract interface class ChecklistProgressRepository {
  Future<Set<String>> load(String planId);
  Future<void> setDone(String planId, String itemId, {required bool done});
}

/// Display preferences chosen by the traveller.
class AppSettings {
  const AppSettings({this.languageCode, this.textScale = 1.0});

  /// Null follows the phone's language.
  final String? languageCode;

  /// Multiplier on top of the phone's own font size (1.0, 1.15 or 1.3).
  final double textScale;

  AppSettings copyWith({String? Function()? languageCode, double? textScale}) =>
      AppSettings(
        languageCode: languageCode == null ? this.languageCode : languageCode(),
        textScale: textScale ?? this.textScale,
      );
}

abstract interface class SettingsRepository {
  Future<bool> onboardingDone();
  Future<void> setOnboardingDone();
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SqliteSavedTripsRepository implements SavedTripsRepository {
  const SqliteSavedTripsRepository(this.database);

  final LocalDatabase database;

  @override
  Future<List<SavedTrip>> all() async {
    final rows = await database.db.query(
      'saved_trips',
      orderBy: 'created_at DESC',
    );
    return [
      for (final row in rows)
        SavedTrip(
          id: row['id']! as String,
          name: row['name']! as String,
          request: TripRequest.fromJson(
            jsonDecode(row['request']! as String) as Json,
          ),
          planId: row['plan_id']! as String,
          createdAt: DateTime.parse(row['created_at']! as String),
        ),
    ];
  }

  @override
  Future<void> save(SavedTrip trip) => database.db.insert('saved_trips', {
    'id': trip.id,
    'name': trip.name,
    'request': jsonEncode(trip.request.toJson()),
    'plan_id': trip.planId,
    'created_at': trip.createdAt.toIso8601String(),
  });

  @override
  Future<void> delete(String id) =>
      database.db.delete('saved_trips', where: 'id = ?', whereArgs: [id]);
}

class SqliteChecklistProgressRepository implements ChecklistProgressRepository {
  const SqliteChecklistProgressRepository(this.database);

  final LocalDatabase database;

  @override
  Future<Set<String>> load(String planId) async {
    final rows = await database.db.query(
      'checklist_progress',
      columns: ['item_id'],
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
    return {for (final row in rows) row['item_id']! as String};
  }

  @override
  Future<void> setDone(
    String planId,
    String itemId, {
    required bool done,
  }) async {
    if (done) {
      await database.db.insert('checklist_progress', {
        'plan_id': planId,
        'item_id': itemId,
        'done_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await database.db.delete(
        'checklist_progress',
        where: 'plan_id = ? AND item_id = ?',
        whereArgs: [planId, itemId],
      );
    }
  }
}

class SqliteSettingsRepository implements SettingsRepository {
  const SqliteSettingsRepository(this.database);

  static const _onboardingKey = 'onboarding_done';
  static const _languageKey = 'language';
  static const _textScaleKey = 'text_scale';

  final LocalDatabase database;

  @override
  Future<bool> onboardingDone() async =>
      await database.getValue(_onboardingKey) == 'true';

  @override
  Future<void> setOnboardingDone() => database.setValue(_onboardingKey, 'true');

  @override
  Future<AppSettings> load() async {
    final language = await database.getValue(_languageKey);
    final scale = double.tryParse(await database.getValue(_textScaleKey) ?? '');
    return AppSettings(
      languageCode: language == null || language.isEmpty ? null : language,
      textScale: scale ?? 1.0,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await database.setValue(_languageKey, settings.languageCode ?? '');
    await database.setValue(_textScaleKey, '${settings.textScale}');
  }
}

/// In-memory implementations for tests and previews.
class MemorySavedTripsRepository implements SavedTripsRepository {
  final _trips = <String, SavedTrip>{};

  @override
  Future<List<SavedTrip>> all() async =>
      _trips.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(SavedTrip trip) async => _trips[trip.id] = trip;

  @override
  Future<void> delete(String id) async => _trips.remove(id);
}

class MemoryChecklistProgressRepository implements ChecklistProgressRepository {
  final _done = <String, Set<String>>{};

  @override
  Future<Set<String>> load(String planId) async => {...?_done[planId]};

  @override
  Future<void> setDone(
    String planId,
    String itemId, {
    required bool done,
  }) async {
    final set = _done.putIfAbsent(planId, () => {});
    done ? set.add(itemId) : set.remove(itemId);
  }
}

class MemorySettingsRepository implements SettingsRepository {
  bool _done = false;
  AppSettings _settings = const AppSettings();

  @override
  Future<bool> onboardingDone() async => _done;

  @override
  Future<void> setOnboardingDone() async => _done = true;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
