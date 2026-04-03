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

  // Lanzar la UI inmediatamente, sin esperar nada
  runApp(
    ProviderScope(
      child: _ScheduledTasksRunner(child: const DoboardApp()),
    ),
  );
}

/// Ejecuta el procesado de tareas programadas en background
/// sin bloquear ni retrasar el render inicial de la app.
class _ScheduledTasksRunner extends ConsumerStatefulWidget {
  const _ScheduledTasksRunner({required this.child});
  final Widget child;

  @override
  ConsumerState<_ScheduledTasksRunner> createState() =>
      _ScheduledTasksRunnerState();
}

class _ScheduledTasksRunnerState extends ConsumerState<_ScheduledTasksRunner> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: no bloquea el arranque
    _runAfterFirstFrame();
  }

  void _runAfterFirstFrame() {
    // Espera al segundo frame para garantizar que la DB ya está abierta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        try {
          await ref
              .read(taskRepositoryProvider)
              .processScheduledTasks('board-hoy');
        } catch (_) {
          // No crítico — se reintentará en el próximo arranque
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}