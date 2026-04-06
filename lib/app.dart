import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'core/providers/database_provider.dart';

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

  /// Drift con WAL gestiona la reconexión de SQLite automáticamente
  /// al volver de background. Invalidar appDatabaseProvider era demasiado
  /// agresivo: reiniciaba todos los streams y causaba que se mostrara
  /// momentáneamente el contenido del tablero 0 (Hoy) independientemente
  /// del tablero activo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sin acción necesaria: los streams de Drift se recuperan solos.
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