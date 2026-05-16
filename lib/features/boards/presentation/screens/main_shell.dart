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
/// Un único [PageView] con orden Hoy → tableros de trabajo → Próximo
/// (sin bucle). El [NavigationBar] se deriva del índice global
/// [mainFlowPageIndexProvider].
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onMainFlowPageChanged(int index) {
    ref.read(mainFlowPageIndexProvider.notifier).state = index;
  }

  void _goToMainFlowPage(int index) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    c.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncProviderAndJump(int index) {
    ref.read(mainFlowPageIndexProvider.notifier).state = index;
    final c = _pageController;
    if (c != null && c.hasClients) {
      c.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workBoardsAsync = ref.watch(workBoardsProvider);
    final visibleBoardsAsync = ref.watch(visibleBoardsProvider);
    final mainFlowPage = ref.watch(mainFlowPageIndexProvider);
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
          final workCount = workBoards.length;
          final pageCount = mainFlowPageCount(workCount);
          final safePage = clampMainFlowPage(mainFlowPage, workCount);

          _pageController ??= PageController(initialPage: safePage);

          if (safePage != mainFlowPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncProviderAndJump(safePage);
            });
          }

          final navSelected =
              navBarSelectedIndexForMainFlowPage(safePage, workCount);
          final onWorkBoard =
              workCount > 0 && safePage >= 1 && safePage <= workCount;
          final currentWorkBoardId =
              onWorkBoard ? workBoards[safePage - 1].id : null;

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController!,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: _onMainFlowPageChanged,
                    itemCount: pageCount,
                    itemBuilder: (context, index) {
                      Widget page;
                      if (index == 0) {
                        page = const HoyScreen();
                      } else if (index == pageCount - 1) {
                        page = const ScheduledTasksScreen();
                      } else {
                        page = WorkBoardPageScaffold(
                          workBoards: workBoards,
                          workBoardIndex: index - 1,
                          onJumpToWorkBoardIndex: (w) =>
                              _goToMainFlowPage(1 + w),
                        );
                      }
                      return MainFlowKeepAlive(child: page);
                    },
                  ),
                ),
                if (isDragging &&
                    currentWorkBoardId != null &&
                    onWorkBoard)
                  visibleBoardsAsync.maybeWhen(
                    data: (allBoards) => BoardDropTargets(
                      boards: allBoards,
                      currentBoardId: currentWorkBoardId,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: navSelected,
              onDestinationSelected: (navIndex) {
                final target = mainFlowPageForNavBarTap(
                  navIndex,
                  workCount,
                  safePage,
                );
                _goToMainFlowPage(target);
              },
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
