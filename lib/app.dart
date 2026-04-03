import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/repository_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/app_settings.dart';

class DoboardApp extends ConsumerStatefulWidget {
  const DoboardApp({super.key});

  @override
  ConsumerState<DoboardApp> createState() => _DoboardAppState();
}

class _DoboardAppState extends ConsumerState<DoboardApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Al volver de background, refresca los streams de datos para evitar
  /// la pantalla negra por pérdida de estado / conexión Drift.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Invalida el provider de la DB para que Drift rehidrate la conexión
      // si el proceso fue suspendido por Android con memoria baja.
      try {
        ref.invalidate(appDatabaseProvider);
      } catch (_) {
        // Ignorar si el provider ya fue desechado
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}