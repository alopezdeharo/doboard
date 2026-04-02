import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      child: _AppInitializer(child: const DoboardApp()),
    ),
  );
}

/// Procesa tareas programadas al arrancar la app.
class _AppInitializer extends ConsumerStatefulWidget {
  const _AppInitializer({required this.child});
  final Widget child;

  @override
  ConsumerState<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Lanzar en post-frame para que los providers estén listos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processScheduledTasks();
    });
  }

  Future<void> _processScheduledTasks() async {
    try {
      // El tablero "Hoy" siempre es el primero visible (board-hoy)
      final moved = await ref
          .read(taskRepositoryProvider)
          .processScheduledTasks('board-hoy');
      if (moved > 0) {
        debugPrint('doboard: $moved tarea(s) movida(s) a Hoy por programación');
      }
    } catch (e) {
      debugPrint('doboard: error procesando tareas programadas: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}