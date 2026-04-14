import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/settings/domain/entities/app_settings.dart';
import 'hoy_screen.dart';
import 'work_boards_screen.dart';
import '../../../boards/presentation/screens/scheduled_tasks_screen.dart';

import '../providers/boards_provider.dart';

/// Shell principal de la app.
///
/// Gestiona la navegación entre las 3 pestañas con [NavigationBar] de
/// Material 3. Usa [IndexedStack] para mantener el estado de cada pestaña
/// (scroll, posición de página) al cambiar entre ellas.
///
/// El escalado de fuente definido en Ajustes se aplica aquí para que
/// afecte uniformemente a todas las pestañas.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      HoyScreen(),
      WorkBoardsScreen(),
      ScheduledTasksScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = ref.watch(shellIndexProvider);

    // Escalado de fuente global desde Ajustes
    final settingsAsync = ref.watch(settingsProvider);
    final fontSize = settingsAsync.valueOrNull?.baseFontSize ?? 14.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontSize / 14.0),
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) =>
          ref.read(shellIndexProvider.notifier).state = i,
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
              label: 'Tableros',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Próximo',
            ),
          ],
        ),
      ),
    );
  }
}