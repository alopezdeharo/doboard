import 'package:flutter/material.dart';

import '../../domain/entities/board.dart';

class BoardNavTabs extends StatelessWidget {
  const BoardNavTabs({
    super.key,
    required this.boards,
    required this.currentIndex,
    required this.onTabTap,
  });

  final List<Board> boards;
  final int currentIndex;
  final ValueChanged<int> onTabTap;

  static const _activeColors = [
    Color(0xFFEFAA27), // Rápidas — ámbar
    Color(0xFF4DB87A), // Medias  — verde
    Color(0xFF5B7FD4), // Largas  — azul índigo
  ];

  String _shortName(String fullName) =>
      fullName.replaceFirst('Tareas ', '').trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Contenedor de pestañas ─────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(boards.length, (i) {
              final board = boards[i];
              final isActive = i == currentIndex;
              final color = i < _activeColors.length
                  ? _activeColors[i]
                  : theme.colorScheme.primary;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive
                          ? Border(
                              bottom: BorderSide(color: color, width: 2.5),
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Icono + nombre en la misma fila ───────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              board.emoji,
                              style: TextStyle(
                                fontSize: isActive ? 15 : 14,
                              ),
                            ),
                            const SizedBox(width: 5),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: theme.textTheme.labelMedium!.copyWith(
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                              ),
                              child: Text(_shortName(board.name)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // ── Subtítulo ──────────────────────────────────────
                        Text(
                          board.subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isActive
                                ? color.withOpacity(0.85)
                                : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Puntos de paginación ───────────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(boards.length, (i) {
            final isActive = i == currentIndex;
            final color = i < _activeColors.length
                ? _activeColors[i]
                : theme.colorScheme.primary;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 8 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
