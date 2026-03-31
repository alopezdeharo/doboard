import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Timer visual compacto que aparece en las tarjetas del tablero "Rápidas".
/// Mantener pulsado → inicia una cuenta atrás de [durationMinutes] minutos.
/// El progreso se muestra como un arco que se va consumiendo en el borde de la tarjeta.
class ExpressTimerWidget extends HookWidget {
  const ExpressTimerWidget({
    super.key,
    this.durationMinutes = 10,
    this.onComplete,
  });

  final int durationMinutes;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = durationMinutes * 60;
    final secondsLeft = useState(totalSeconds);
    final isRunning = useState(false);
    final timerRef = useRef<Timer?>(null);
    final theme = Theme.of(context);

    void stop() {
      timerRef.value?.cancel();
      isRunning.value = false;
      secondsLeft.value = totalSeconds;
    }

    void start() {
      if (isRunning.value) {
        stop();
        return;
      }
      HapticFeedback.mediumImpact();
      isRunning.value = true;
      timerRef.value = Timer.periodic(const Duration(seconds: 1), (_) {
        if (secondsLeft.value <= 1) {
          stop();
          HapticFeedback.heavyImpact();
          onComplete?.call();
          return;
        }
        secondsLeft.value--;
      });
    }

    useEffect(() => () => timerRef.value?.cancel(), []);

    final progress = secondsLeft.value / totalSeconds;
    final minutes = secondsLeft.value ~/ 60;
    final seconds = secondsLeft.value % 60;
    final isStarted = secondsLeft.value < totalSeconds;

    // Color: verde → naranja → rojo según el tiempo restante
    final color = Color.lerp(
      const Color(0xFF1D9E75),
      const Color(0xFFE24B4A),
      1 - progress,
    )!;

    return GestureDetector(
      onTap: start,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arco de progreso
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: isStarted ? progress : 1.0,
                strokeWidth: 2.5,
                backgroundColor: isStarted
                    ? theme.colorScheme.outlineVariant.withOpacity(0.3)
                    : Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isStarted ? color : theme.colorScheme.outlineVariant.withOpacity(0.4),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),

            // Display
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isStarted
                  ? Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                key: const ValueKey('timer'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
                  : Icon(
                Icons.timer_outlined,
                key: const ValueKey('icon'),
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}