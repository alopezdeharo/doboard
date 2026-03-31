import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/boards/data/repositories/board_repository_impl.dart';
import '../../features/boards/domain/repositories/i_board_repository.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/i_task_repository.dart';
import 'database_provider.dart';

final boardRepositoryProvider = Provider<IBoardRepository>((ref) {
  return BoardRepositoryImpl(ref.watch(appDatabaseProvider));
});

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(appDatabaseProvider));
});