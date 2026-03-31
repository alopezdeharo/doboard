import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InputPosition { top, bottom }
enum AppThemeMode { light, dark, system }

class AppSettings {
  const AppSettings({
    this.inputPosition = InputPosition.bottom,
    this.baseFontSize = 14.0,
    this.automationsEnabled = true,
    this.frogEnabled = true,
    this.expressTimerEnabled = true,
    this.showCompletedTasks = false,
    this.themeMode = AppThemeMode.system,
  });

  final InputPosition inputPosition;
  final double baseFontSize;
  final bool automationsEnabled;
  final bool frogEnabled;
  final bool expressTimerEnabled;
  final bool showCompletedTasks;
  final AppThemeMode themeMode;

  AppSettings copyWith({
    InputPosition? inputPosition, double? baseFontSize,
    bool? automationsEnabled, bool? frogEnabled,
    bool? expressTimerEnabled, bool? showCompletedTasks,
    AppThemeMode? themeMode,
  }) => AppSettings(
    inputPosition: inputPosition ?? this.inputPosition,
    baseFontSize: baseFontSize ?? this.baseFontSize,
    automationsEnabled: automationsEnabled ?? this.automationsEnabled,
    frogEnabled: frogEnabled ?? this.frogEnabled,
    expressTimerEnabled: expressTimerEnabled ?? this.expressTimerEnabled,
    showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
    themeMode: themeMode ?? this.themeMode,
  );

  /// Convierte el enum propio al ThemeMode de Flutter.
  ThemeMode get flutterThemeMode => switch (themeMode) {
    AppThemeMode.light  => ThemeMode.light,
    AppThemeMode.dark   => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}

const _kInputPosition = 'input_position';
const _kFontSize      = 'font_size';
const _kAutomations   = 'automations_enabled';
const _kFrog          = 'frog_enabled';
const _kTimer         = 'timer_enabled';
const _kShowCompleted = 'show_completed';
const _kThemeMode     = 'theme_mode';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  AppSettings _load() => AppSettings(
    inputPosition: InputPosition.values[_prefs.getInt(_kInputPosition) ?? 1],
    baseFontSize: _prefs.getDouble(_kFontSize) ?? 14.0,
    automationsEnabled: _prefs.getBool(_kAutomations) ?? true,
    frogEnabled: _prefs.getBool(_kFrog) ?? true,
    expressTimerEnabled: _prefs.getBool(_kTimer) ?? true,
    showCompletedTasks: _prefs.getBool(_kShowCompleted) ?? false,
    // Por defecto system → respeta el modo del móvil
    themeMode: AppThemeMode.values[_prefs.getInt(_kThemeMode) ?? 2],
  );

  Future<void> setInputPosition(InputPosition pos) async {
    await _prefs.setInt(_kInputPosition, pos.index);
    state = AsyncData(state.value!.copyWith(inputPosition: pos));
  }

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_kFontSize, size);
    state = AsyncData(state.value!.copyWith(baseFontSize: size));
  }

  Future<void> toggleAutomations() async {
    final next = !state.value!.automationsEnabled;
    await _prefs.setBool(_kAutomations, next);
    state = AsyncData(state.value!.copyWith(automationsEnabled: next));
  }

  Future<void> toggleFrog() async {
    final next = !state.value!.frogEnabled;
    await _prefs.setBool(_kFrog, next);
    state = AsyncData(state.value!.copyWith(frogEnabled: next));
  }

  Future<void> toggleTimer() async {
    final next = !state.value!.expressTimerEnabled;
    await _prefs.setBool(_kTimer, next);
    state = AsyncData(state.value!.copyWith(expressTimerEnabled: next));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs.setInt(_kThemeMode, mode.index);
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }
}

final settingsProvider =
AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);