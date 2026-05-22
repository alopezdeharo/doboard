import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/settings/domain/entities/app_settings.dart';
import 'hoy_screen.dart';
import 'work_boards_screen.dart';
import 'scheduled_tasks_screen.dart';
import '../providers/boards_provider.dart';
import '../widgets/board_drop_target.dart';
import '../widgets/main_flow_keep_alive.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';

/// Shell principal de la app.
///
/// [PageView] fijo de 3 páginas: Hoy · Tareas · Próximo.
/// El cambio entre tableros de trabajo (Rápidas/Medias/Largas) ocurre
/// DENTRO de la página Tareas sin reconstruir el shell.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMainFlowPageChanged(int index) {
    ref.read(mainFlowPageIndexProvider.notifier).state = index;
  }

  void _goToMainFlowPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workBoardsAsync = ref.watch(workBoardsProvider);
    final visibleBoardsAsync = ref.watch(visibleBoardsProvider);
    final mainFlowPage = ref.watch(mainFlowPageIndexProvider);
    final activeWorkBoardIndex = ref.watch(activeWorkBoardIndexProvider);
    final isDragging = ref.watch(dragStateProvider) != null;

    final settingsAsync = ref.watch(settingsProvider);
    final fontSize = settingsAsync.valueOrNull?.baseFontSize ?? 14.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontSize / 14.0),
      ),
      child: workBoardsAsync.when(
        loading: () => Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Center(child: Text('Error: $e')),
        ),
        data: (workBoards) {
          // Determinar qué tablero está activo para los drag targets.
          final safeWorkIndex =
              activeWorkBoardIndex.clamp(0, (workBoards.length - 1).clamp(0, 999));
          final onWorkBoards = mainFlowPage == 1 && workBoards.isNotEmpty;
          final currentWorkBoardId =
              onWorkBoards ? workBoards[safeWorkIndex].id : null;

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Stack(
              children: [
                // ── Flujo de 3 páginas ──────────────────────────────────────
                Positioned.fill(
                  child: PageView(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: _onMainFlowPageChanged,
                    children: [
                      // 0 — Hoy
                      const MainFlowKeepAlive(child: HoyScreen()),

                      // 1 — Tareas (shell persistente con boards internos)
                      MainFlowKeepAlive(
                        child: WorkBoardPageScaffold(
                          workBoards: workBoards,
                        ),
                      ),

                      // 2 — Próximo
                      const MainFlowKeepAlive(child: ScheduledTasksScreen()),
                    ],
                  ),
                ),

                // ── Drag-and-drop targets ──────────────────────────────────
                if (isDragging && currentWorkBoardId != null && onWorkBoards)
                  visibleBoardsAsync.maybeWhen(
                    data: (allBoards) => BoardDropTargets(
                      boards: allBoards,
                      currentBoardId: currentWorkBoardId,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
              ],
            ),

            // ── Barra de navegación inferior ───────────────────────────────
            bottomNavigationBar: NavigationBar(
              selectedIndex: mainFlowPage.clamp(0, 2),
              onDestinationSelected: _goToMainFlowPage,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today_rounded),
                  label: 'Hoy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_week_outlined),
                  selectedIcon: Icon(Icons.view_week_rounded),
                  label: 'Tareas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note_rounded),
                  label: 'Próximo',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
