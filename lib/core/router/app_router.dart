import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/boards/presentation/screens/main_shell.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_focus_screen.dart';

abstract final class AppRoutes {
  static const home        = '/';
  static const taskDetail  = '/task/:taskId';
  static const taskFocus   = '/task/:taskId/focus';
  static const noteEditor  = '/task/:taskId/note';
  static const settings    = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    // La ruta raíz ahora apunta al MainShell con NavigationBar.
    // El shell mantiene Hoy / Tableros / Próximo en un IndexedStack.
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const MainShell(),
    ),
    GoRoute(
      path: AppRoutes.taskDetail,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _slideUpPage(state.pageKey, TaskDetailScreen(taskId: taskId));
      },
    ),
    GoRoute(
      path: AppRoutes.taskFocus,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _fadeScalePage(state.pageKey, TaskFocusScreen(taskId: taskId));
      },
    ),
    GoRoute(
      path: AppRoutes.noteEditor,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _slideUpPage(state.pageKey, NoteEditorScreen(taskId: taskId));
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) =>
          _slideUpPage(state.pageKey, const SettingsScreen()),
    ),
  ],
);

CustomTransitionPage<void> _slideUpPage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

CustomTransitionPage<void> _fadeScalePage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}