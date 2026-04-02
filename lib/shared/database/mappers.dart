import 'package:doboard/features/boards/domain/entities/board.dart';
import 'package:doboard/features/notes/domain/entities/note.dart';
import 'package:doboard/features/tasks/domain/entities/priority.dart';
import 'package:doboard/features/tasks/domain/entities/subtask.dart';
import 'package:doboard/features/tasks/domain/entities/task.dart';
import 'package:doboard/shared/database/app_database.dart';
import 'package:drift/drift.dart';

extension BoardDataMapper on BoardData {
  Board toBoard() => Board(
    id: id, name: name, subtitle: subtitle, colorHex: colorHex,
    emoji: emoji, position: position, isVisible: isVisible,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
  );
}
extension BoardEntityMapper on Board {
  BoardsCompanion toCompanion() => BoardsCompanion(
    id: Value(id), name: Value(name), subtitle: Value(subtitle),
    colorHex: Value(colorHex), emoji: Value(emoji),
    position: Value(position), isVisible: Value(isVisible),
    createdAt: Value(createdAt.millisecondsSinceEpoch),
  );
}

extension TaskDataMapper on TaskData {
  Task toTask() => Task(
    id: id, boardId: boardId, title: title, content: content,
    priority: Priority.fromValue(priority), position: position,
    isDone: isDone, isFrog: isFrog, isPinned: isPinned,
    detectedKeyword: detectedKeyword,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    completedAt: completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(completedAt!)
        : null,
    parentTaskTitle: parentTaskTitle,
    scheduledDate: scheduledDate != null
        ? DateTime.fromMillisecondsSinceEpoch(scheduledDate!)
        : null,
  );
}
extension TaskEntityMapper on Task {
  TasksCompanion toCompanion() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TasksCompanion(
      id: Value(id), boardId: Value(boardId), title: Value(title),
      content: Value(content), priority: Value(priority.value),
      position: Value(position), isDone: Value(isDone), isFrog: Value(isFrog),
      isPinned: Value(isPinned), detectedKeyword: Value(detectedKeyword),
      createdAt: Value(createdAt.millisecondsSinceEpoch), updatedAt: Value(now),
      completedAt: Value(completedAt?.millisecondsSinceEpoch),
      parentTaskTitle: Value(parentTaskTitle),
      scheduledDate: Value(scheduledDate?.millisecondsSinceEpoch),
    );
  }
}

extension SubtaskDataMapper on SubtaskData {
  Subtask toSubtask() => Subtask(
    id: id, taskId: taskId, title: title, isDone: isDone,
    position: position,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    isPromoted: isPromoted,
  );
}
extension SubtaskEntityMapper on Subtask {
  SubtasksCompanion toCompanion() => SubtasksCompanion(
    id: Value(id), taskId: Value(taskId), title: Value(title),
    isDone: Value(isDone), position: Value(position),
    createdAt: Value(createdAt.millisecondsSinceEpoch),
    isPromoted: Value(isPromoted),
  );
}

extension NoteDataMapper on NoteData {
  Note toNote() => Note(
    id: id, taskId: taskId, contentJson: contentJson, plainText: plainText,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}
extension NoteEntityMapper on Note {
  NotesCompanion toCompanion() => NotesCompanion(
    id: Value(id), taskId: Value(taskId), contentJson: Value(contentJson),
    plainText: Value(plainText),
    createdAt: Value(createdAt.millisecondsSinceEpoch),
    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );
}