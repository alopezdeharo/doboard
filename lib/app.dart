import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/app_settings.dart';

class DoboardApp extends ConsumerWidget {
  const DoboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    final themeMode = settingsAsync.maybeWhen(
      data: (s) => s.flutterThemeMode,
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      title: 'doboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      // Requerido por flutter_quill para localización del editor
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}