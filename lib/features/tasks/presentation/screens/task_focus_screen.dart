import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';

class TaskFocusScreen extends HookConsumerWidget {
  const TaskFocusScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = useState<Task?>(null);

    useEffect(() {
      ref.read(taskRepositoryProvider).getTaskById(taskId).then((t) {
        taskState.value = t;
      });
      return null;
    }, [taskId]);

    final task = taskState.value;
    if (task == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _FocusView(task: task);
  }
}

class _FocusView extends HookConsumerWidget {
  const _FocusView({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerMode = useState<_TimerMode>(_TimerMode.pomodoro);
    final secondsLeft = useState(_secondsFor(_TimerMode.pomodoro));
    final isRunning = useState(false);
    final timerRef = useRef<Timer?>(null);

    void tick() {
      if (secondsLeft.value <= 1) {
        isRunning.value = false;
        timerRef.value?.cancel();
        HapticFeedback.heavyImpact();
        secondsLeft.value = 0;
        return;
      }
      secondsLeft.value--;
    }

    void startPause() {
      if (isRunning.value) {
        timerRef.value?.cancel();
        isRunning.value = false;
      } else {
        HapticFeedback.selectionClick();
        isRunning.value = true;
        timerRef.value =
            Timer.periodic(const Duration(seconds: 1), (_) => tick());
      }
    }

    void setMode(_TimerMode mode) {
      timerRef.value?.cancel();
      timerMode.value = mode;
      secondsLeft.value = _secondsFor(mode);
      isRunning.value = false;
    }

    useEffect(() => () => timerRef.value?.cancel(), []);

    final progress = secondsLeft.value / _secondsFor(timerMode.value);
    final minutes = secondsLeft.value ~/ 60;
    final seconds = secondsLeft.value % 60;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: FadeIn(
          duration: const Duration(milliseconds: 350),
          child: Column(
            children: [
              // Barra superior
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 28, color: Colors.white54),
                      onPressed: () {
                        timerRef.value?.cancel();
                        SystemChrome.setSystemUIOverlayStyle(
                            SystemUiOverlayStyle.dark);
                        context.pop();
                      },
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(taskActionsProvider.notifier)
                            .toggleDone(task.id, isDone: true);
                        timerRef.value?.cancel();
                        context.pop();
                      },
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFF5DCAA5)),
                      label: const Text('Completar',
                          style: TextStyle(
                              color: Color(0xFF5DCAA5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    if (task.isFrog)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('🐸', style: TextStyle(fontSize: 28)),
                      ),
                    Text(
                      task.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                    ),
                    if (task.content != null && task.content!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.content!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Círculo timer
              GestureDetector(
                onTap: startPause,
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _colorForMode(timerMode.value)),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isRunning.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Selector de modo — FittedBox para adaptarse a cualquier pantalla
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _TimerMode.values.map((mode) {
                      final isActive = mode == timerMode.value;
                      return GestureDetector(
                        onTap: () => setMode(mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white12
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                isActive ? Colors.white30 : Colors.white12),
                          ),
                          child: Text(
                            mode.label,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white38,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Spacer(),

              if (task.hasSubtasks)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _FocusSubtasks(task: task),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static int _secondsFor(_TimerMode mode) => switch (mode) {
    _TimerMode.pomodoro => 25 * 60,
    _TimerMode.short => 5 * 60,
    _TimerMode.long => 15 * 60,
  };

  static Color _colorForMode(_TimerMode mode) => switch (mode) {
    _TimerMode.pomodoro => const Color(0xFF5DCAA5),
    _TimerMode.short => const Color(0xFF85B7EB),
    _TimerMode.long => const Color(0xFFFAC775),
  };
}

// Labels cortos para caber en pantallas pequeñas
enum _TimerMode {
  pomodoro('Pomodoro · 25m'),
  short('Descanso · 5m'),
  long('Descanso largo · 15m');

  const _TimerMode(this.label);
  final String label;
}

class _FocusSubtasks extends ConsumerWidget {
  const _FocusSubtasks({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(subtasksByTaskProvider(task.id));
    final actions = ref.read(taskActionsProvider.notifier);

    return subtasksAsync.maybeWhen(
      data: (subtasks) {
        final pending = subtasks.where((s) => !s.isDone).take(3).toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subtareas pendientes',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            ...pending.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () =>
                    actions.toggleSubtaskDone(s.id, isDone: true),
                child: Row(children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border:
                      Border.all(color: Colors.white24, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.title,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                  ),
                ]),
              ),
            )),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}