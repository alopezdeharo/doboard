import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/providers/repository_providers.dart';
import 'core/services/notification_service.dart';
import 'widgets/home/today_tasks_widget_updater.dart';
import 'widgets/home/widget_callback_dispatcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(widgetCallbackDispatcher);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await NotificationService.instance.initialize();
  await initializeDateFormatting('es');

  runApp(
    ProviderScope(
      child: _ScheduledTasksRunner(child: const DoboardApp()),
    ),
  );
}

/// Ejecuta el procesado de tareas programadas y mantiene el widget «Hoy»
/// sincronizado en tiempo real mediante un stream reactivo sobre la DB.
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
  StreamSubscription<Object>? _todayTasksSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runAfterFirstFrame();
  }

  @override
  void dispose() {
    _todayTasksSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-suscribir fuerza a Drift a re-emitir el estado actual de la DB,
      // recogiendo cualquier cambio que el background isolate del widget
      // haya escrito mientras la app estaba en segundo plano.
      _subscribeTodayTasksStream();
      _runScheduledTasksProcessing();
    }
  }

  void _runAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        _subscribeTodayTasksStream();
        await _runScheduledTasksProcessing();
      });
    });
  }

  /// Cancela y re-crea la suscripción.
  ///
  /// Re-suscribirse al stream de Drift provoca una re-query inmediata,
  /// lo que garantiza que la UI (y el widget) reflejen el estado real
  /// de la DB aunque el último write lo haya hecho otro isolate.
  void _subscribeTodayTasksStream() {
    _todayTasksSub?.cancel();
    _todayTasksSub = ref
        .read(taskRepositoryProvider)
        .watchTasksByBoard('board-hoy')
        .listen(
          (tasks) => TodayTasksWidgetUpdater.update(tasks),
          onError: (_) {},
        );
  }

  Future<void> _runScheduledTasksProcessing() async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;
    try {
      await ref
          .read(taskRepositoryProvider)
          .processScheduledTasks('board-hoy');
    } catch (_) {
      // No crítico — se reintentará en próximo resume/arranque.
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
