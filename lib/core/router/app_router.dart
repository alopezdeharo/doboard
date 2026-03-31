import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/boards/presentation/screens/boards_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_focus_screen.dart';

/// Nombres de ruta centralizados — usar siempre estas constantes.
abstract final class AppRoutes {
  static const home = '/';
  static const taskDetail = '/task/:taskId';
  static const taskFocus = '/task/:taskId/focus';
  static const noteEditor = '/task/:taskId/note';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const BoardsScreen(),
    ),
    GoRoute(
      path: AppRoutes.taskDetail,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _slideUpPage(
          state.pageKey,
          TaskDetailScreen(taskId: taskId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.taskFocus,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _fadeScalePage(
          state.pageKey,
          TaskFocusScreen(taskId: taskId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.noteEditor,
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return _slideUpPage(
          state.pageKey,
          NoteEditorScreen(taskId: taskId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => _slideUpPage(
        state.pageKey,
        const SettingsScreen(),
      ),
    ),
  ],
);

/// Transición: sube desde abajo (para bottom sheets y detalles)
CustomTransitionPage<void> _slideUpPage(
    LocalKey key,
    Widget child,
    ) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

/// Transición: fade + ligero scale (para modo enfoque)
CustomTransitionPage<void> _fadeScalePage(
    LocalKey key,
    Widget child,
    ) {
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