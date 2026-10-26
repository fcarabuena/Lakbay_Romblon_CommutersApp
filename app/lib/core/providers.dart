import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import 'data/user_repositories.dart';

/// Loaded once at startup from the local database (see `main.dart`) and
/// overridden there, so every screen can read travel data synchronously.
final initialTravelDataProvider = Provider<TravelData>(
  (ref) => throw UnimplementedError('initialTravelDataProvider'),
);

/// The travel data every screen reads. Starts as [initialTravelDataProvider]
/// and is replaced after a successful sync.
class TravelDataController extends Notifier<TravelData> {
  @override
  TravelData build() => ref.watch(initialTravelDataProvider);

  void replace(TravelData data) => state = data;
}

final travelDataProvider = NotifierProvider<TravelDataController, TravelData>(
  TravelDataController.new,
);

/// Whether onboarding was finished before this launch.
final onboardingDoneAtStartProvider = Provider<bool>((ref) => true);

final routePlannerProvider = Provider<RoutePlanner>(
  (ref) => RoutePlanner(ref.watch(travelDataProvider)),
);

final savedTripsRepositoryProvider = Provider<SavedTripsRepository>(
  (ref) => throw UnimplementedError('savedTripsRepositoryProvider'),
);

final checklistProgressRepositoryProvider =
    Provider<ChecklistProgressRepository>(
      (ref) => throw UnimplementedError('checklistProgressRepositoryProvider'),
    );

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepositoryProvider'),
);

/// Current time, overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
