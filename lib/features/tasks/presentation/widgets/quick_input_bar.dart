import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/tasks_provider.dart';
import '../../../../core/utils/automation_engine.dart';
import '../../../../features/settings/domain/entities/app_settings.dart';

class QuickInputBar extends HookConsumerWidget {
  const QuickInputBar({super.key, required this.boardId});
  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final hasText = useState(false);
    final detectedKeyword = useState<String?>(null);
    final theme = Theme.of(context);

    // Lee el ajuste de automatizaciones
    final automationsEnabled = ref.watch(settingsProvider).maybeWhen(
      data: (s) => s.automationsEnabled,
      orElse: () => true,
    );

    void onTextChanged(String value) {
      hasText.value = value.trim().isNotEmpty;
      // Solo detecta keywords si las automatizaciones están activas
      detectedKeyword.value = automationsEnabled
          ? AutomationEngine.instance.detect(value)
          : null;
    }

    Future<void> createTask() async {
      final title = controller.text.trim();
      if (title.isEmpty) return;
      HapticFeedback.selectionClick();
      controller.clear();
      hasText.value = false;
      detectedKeyword.value = null;
      await ref.read(taskActionsProvider.notifier).createTask(
        boardId: boardId,
        title: title,
      );
    }

    void onPlusTap() {
      if (hasText.value) {
        createTask();
      } else {
        focusNode.requestFocus();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlusTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: hasText.value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: detectedKeyword.value != null && !hasText.value
                    ? Text(detectedKeyword.value!,
                    key: ValueKey(detectedKeyword.value),
                    style: const TextStyle(fontSize: 18))
                    : Icon(
                  hasText.value
                      ? Icons.arrow_upward_rounded
                      : Icons.add_rounded,
                  key: ValueKey(hasText.value),
                  size: 18,
                  color: hasText.value
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onTextChanged,
              onSubmitted: (_) => createTask(),
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Nueva tarea...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (detectedKeyword.value != null && hasText.value)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(detectedKeyword.value!,
                  style: const TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );
  }
}