import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class Settings {
  const Settings({required this.darkMode, required this.sound, required this.onboarded});

  final bool darkMode;
  final bool sound;
  final bool onboarded;

  Settings copyWith({bool? darkMode, bool? sound, bool? onboarded}) => Settings(
        darkMode: darkMode ?? this.darkMode,
        sound: sound ?? this.sound,
        onboarded: onboarded ?? this.onboarded,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  Box<dynamic> get _box => Hive.box<dynamic>('settings');

  @override
  Settings build() => Settings(
        darkMode: _box.get('darkMode', defaultValue: false) as bool,
        sound: _box.get('sound', defaultValue: true) as bool,
        onboarded: _box.get('onboarded', defaultValue: false) as bool,
      );

  void setDarkMode(bool value) {
    _box.put('darkMode', value);
    state = state.copyWith(darkMode: value);
  }

  void setSound(bool value) {
    _box.put('sound', value);
    state = state.copyWith(sound: value);
  }

  void completeOnboarding() {
    _box.put('onboarded', true);
    state = state.copyWith(onboarded: true);
  }

  /// Home-visit counter for the "rate us" popup (every 3rd visit).
  int bumpHomeVisits() {
    final visits = (_box.get('homeVisits', defaultValue: 0) as int) + 1;
    _box.put('homeVisits', visits);
    return visits;
  }

  bool get ratePopupDismissedForever =>
      _box.get('rateDismissed', defaultValue: false) as bool;

  void dismissRateForever() => _box.put('rateDismissed', true);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
