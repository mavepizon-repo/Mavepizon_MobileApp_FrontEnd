import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/storage_helper.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    // Read the saved theme synchronously (StorageHelper is preloaded in main())
    // so the very first frame already uses the user's choice — no light flash
    // and no reset after closing/reopening the app.
    _loadSync();
    reload();
  }

  void _loadSync() {
    try {
      final mode = StorageHelper.getThemeModeSync(
          userId: StorageHelper.getUserIdSync());
      if (mode == 'dark') state = ThemeMode.dark;
    } catch (_) {
      // init() not yet complete (e.g. tests) — keep the light default.
    }
  }

  /// Re-reads the theme for the current logged-in user (defaults to light).
  Future<void> reload() async {
    final userId = await StorageHelper.getUserId();
    final mode = await StorageHelper.getThemeMode(userId: userId);
    state = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final userId = await StorageHelper.getUserId();
    await StorageHelper.saveThemeMode(
      mode == ThemeMode.dark ? 'dark' : 'light',
      userId: userId,
    );
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});