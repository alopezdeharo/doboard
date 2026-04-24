import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/providers/repository_providers.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  // Inicializar notificaciones (registra canales Android, configura iOS)
  await NotificationService.instance.initialize();
  await initializeDateFormatting('es');

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

class _ScheduledTasksRunnerState extends ConsumerState<_ScheduledTasksRunner>
    with WidgetsBindingObserver {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fire-and-forget: no bloquea el arranque
    _runAfterFirstFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runScheduledTasksProcessing();
    }
  }

  void _runAfterFirstFrame() {
    // Espera al segundo frame para garantizar que la DB ya está abierta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(_runScheduledTasksProcessing);
    });
  }

  Future<void> _runScheduledTasksProcessing() async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;
    try {
      await ref.read(taskRepositoryProvider).processScheduledTasks('board-hoy');
    } catch (_) {
      // No crítico — se reintentará en próximo resume/arranque.
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}