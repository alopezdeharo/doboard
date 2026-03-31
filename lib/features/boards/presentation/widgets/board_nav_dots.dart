import 'package:flutter/material.dart';

class BoardNavDots extends StatelessWidget {
  const BoardNavDots({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.onDotTap,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return GestureDetector(
          onTap: () => onDotTap(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              // Dot activo: píldora ancha; inactivo: círculo pequeño
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.75)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}