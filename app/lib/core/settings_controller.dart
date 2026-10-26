import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/user_repositories.dart';
import 'providers.dart';

/// Settings read at startup (see `main.dart`), so the first frame already
/// uses the chosen language and text size.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> setLanguage(String? code) =>
      _update(state.copyWith(languageCode: () => code));

  Future<void> setTextScale(double scale) =>
      _update(state.copyWith(textScale: scale));

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

/// The text size choices, as multipliers on the phone's own font size.
const textScaleOptions = [1.0, 1.15, 1.3];

/// Combines the phone's font size with the app's text size setting.
TextScaler combinedTextScaler(TextScaler system, double appScale) {
  final systemFactor = system.scale(16) / 16;
  return TextScaler.linear(systemFactor * appScale);
}
