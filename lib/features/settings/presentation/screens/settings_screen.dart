import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/automation_engine.dart';
import '../../../../features/boards/domain/entities/board.dart';
import '../../../../features/boards/presentation/providers/boards_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Ajustes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: settingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (settings) => ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tableros
                    _SectionHeader('Tableros'),
                    const _BoardVisibilitySection(),
                    const SizedBox(height: 8),

                    // Interfaz
                    _SectionHeader('Interfaz'),
                    _SettingsCard(children: [
                      _SwitchTile(
                        icon: Icons.vertical_align_bottom_rounded,
                        label: 'Input de tareas abajo',
                        subtitle: 'Posición del campo para nueva tarea',
                        value: settings.inputPosition == InputPosition.bottom,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setInputPosition(
                          v ? InputPosition.bottom : InputPosition.top,
                        ),
                      ),
                      _Divider(),
                      _FontSizeTile(
                        value: settings.baseFontSize,
                        onChanged: (v) =>
                            ref.read(settingsProvider.notifier).setFontSize(v),
                      ),
                      _Divider(),
                      _ThemeModeTile(
                        current: settings.themeMode,
                        onChanged: (mode) =>
                            ref.read(settingsProvider.notifier).setThemeMode(mode),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // Productividad
                    _SectionHeader('Productividad'),
                    _SettingsCard(children: [
                      _SwitchTile(
                        icon: null,
                        emoji: '🐸',
                        label: 'Eat the Frog',
                        subtitle: 'Marca tu tarea más importante del día',
                        value: settings.frogEnabled,
                        onChanged: (_) =>
                            ref.read(settingsProvider.notifier).toggleFrog(),
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.timer_outlined,
                        label: 'Timer express',
                        subtitle: 'Pomodoro en modo enfoque',
                        value: settings.expressTimerEnabled,
                        onChanged: (_) =>
                            ref.read(settingsProvider.notifier).toggleTimer(),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // Automatizaciones
                    _SectionHeader('Automatizaciones'),
                    _SettingsCard(children: [
                      _SwitchTile(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Detección de palabras clave',
                        subtitle: 'Añade iconos automáticos según el texto',
                        value: settings.automationsEnabled,
                        onChanged: (_) => ref
                            .read(settingsProvider.notifier)
                            .toggleAutomations(),
                      ),
                    ]),
                    if (settings.automationsEnabled) ...[
                      const SizedBox(height: 8),
                      const _AutomationRulesList(),
                    ],
                    const SizedBox(height: 8),

                    // Tips
                    _SectionHeader('Aprende el sistema'),
                    const _TipsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Visibilidad de tableros ──────────────────────────────────────────────────

class _BoardVisibilitySection extends ConsumerWidget {
  const _BoardVisibilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allBoardsProvider);

    return allAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (boards) => _SettingsCard(
        children: boards.asMap().entries.map((e) {
          return Column(
            children: [
              _SwitchTile(
                icon: null,
                emoji: e.value.emoji,
                label: e.value.name,
                subtitle: e.value.subtitle,
                value: e.value.isVisible,
                onChanged: (v) async {
                  // Si está ocultando (v=false), comprobar si tiene tareas
                  if (!v) {
                    final taskCount = await ref
                        .read(taskRepositoryProvider)
                        .countPendingByBoard(e.value.id);
                    if (taskCount > 0 && context.mounted) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Ocultar ${e.value.name}'),
                          content: Text(
                            'Este tablero tiene $taskCount tarea${taskCount == 1 ? '' : 's'} pendiente${taskCount == 1 ? '' : 's'}.\n\n'
                                'Las tareas se conservarán pero no serán visibles hasta que vuelvas a mostrar el tablero.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Ocultar igualmente'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }
                  }
                  ref.read(boardRepositoryProvider)
                      .toggleVisibility(e.value.id, isVisible: v);
                },
              ),
              if (e.key < boards.length - 1) _Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tema: selector de 3 estados ─────────────────────────────────────────────

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.current, required this.onChanged});

  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila con icono y label
          Row(
            children: [
              Icon(
                Icons.brightness_6_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text('Tema', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented button ocupa todo el ancho disponible
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 16),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.auto_mode_rounded, size: 16),
                  label: Text('Automático'),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 16),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {current},
              onSelectionChanged: (modes) => onChanged(modes.first),
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tamaño de fuente ─────────────────────────────────────────────────────────

class _FontSizeTile extends StatelessWidget {
  const _FontSizeTile({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text('Tamaño de texto', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${value.round()}px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: 12,
              max: 18,
              divisions: 6,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de automatizaciones ────────────────────────────────────────────────

class _AutomationRulesList extends StatelessWidget {
  const _AutomationRulesList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = AutomationEngine.instance.allRules;

    return _SettingsCard(
      children: rules.asMap().entries.map((e) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Text(e.value.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.label, style: theme.textTheme.bodyMedium),
                        Text(
                          e.value.triggers,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (e.key < rules.length - 1) _Divider(),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Tips ─────────────────────────────────────────────────────────────────────

class _TipsSection extends StatelessWidget {
  const _TipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
      emoji: '🐸',
      title: 'Eat the Frog',
      body:
      'Marca tu tarea más difícil como "rana". Complétala antes que nada. El resto del día será más fácil.',
      ),
      (
      emoji: '⚡',
      title: 'Rápidas primero',
      body:
      'Si una tarea tarda menos de 10 minutos, ponla en Rápidas y hazla ahora. No necesita planificación.',
      ),
      (
      emoji: '🧘',
      title: 'Con calma',
      body:
      'Para tareas de 30–60 minutos usa el modo enfoque con el timer Pomodoro. 25 minutos de concentración real.',
      ),
      (
      emoji: '🌿',
      title: 'Sin prisa',
      body:
      'Las tareas largas (+1h) necesitan subtareas. Divídelas en pasos concretos. El progreso visible motiva.',
      ),
      (
      emoji: '📋',
      title: 'Hoy es sagrado',
      body:
      'Nunca pongas más de 7 tareas en Hoy. Si hay más, mueve las menos urgentes a otro tablero.',
      ),
    ];

    return Column(
      children: tips
          .map(
            (tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TipCard(emoji: tip.emoji, title: tip.title, body: tip.body),
        ),
      )
          .toList(),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Componentes compartidos ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.emoji,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final String? emoji;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 18))
          else if (icon != null)
            Icon(icon, size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 46,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }
}

// ─── Extensión: visibilidad con aviso ────────────────────────────────────────
// (Añadir en _BoardVisibilitySection.onChanged)