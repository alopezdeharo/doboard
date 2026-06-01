import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/task.dart';

/// Stream de la rana activa en toda la app. Null si no hay ninguna.
final frogTaskProvider = StreamProvider<Task?>((ref) {
  return ref.watch(taskRepositoryProvider).watchFrogTask();
});
