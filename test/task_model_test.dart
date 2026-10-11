import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_assignment/models/task_model.dart';

void main() {
  group('TaskModel', () {
    final dueDate = DateTime(2026, 10, 15, 14, 30);
    final createdAt = DateTime(2026, 10, 10, 9, 0);

    test('serializes all required task fields for Firestore', () {
      final task = TaskModel(
        id: 'task-123',
        title: 'Complete assignment',
        description: 'Finish the Firebase task manager.',
        dueDate: dueDate,
        priority: TaskPriority.high,
        completed: false,
        createdAt: createdAt,
        userId: 'user-123',
      );

      final data = task.toFirestore();

      expect(data['title'], 'Complete assignment');
      expect(data['description'], 'Finish the Firebase task manager.');
      expect((data['dueDate'] as Timestamp).toDate(), dueDate);
      expect(data['priority'], 'high');
      expect(data['completed'], isFalse);
      expect((data['createdAt'] as Timestamp).toDate(), createdAt);
      expect(data['userId'], 'user-123');
      expect(data['courseBucket'], 'CS 421');
    });

    test('copyWith changes completion without losing task details', () {
      final task = TaskModel(
        id: 'task-123',
        title: 'Complete assignment',
        description: 'Finish the Firebase task manager.',
        dueDate: dueDate,
        priority: TaskPriority.medium,
        completed: false,
        createdAt: createdAt,
        userId: 'user-123',
      );

      final completedTask = task.copyWith(completed: true);

      expect(completedTask.completed, isTrue);
      expect(completedTask.id, task.id);
      expect(completedTask.title, task.title);
      expect(completedTask.description, task.description);
      expect(completedTask.dueDate, task.dueDate);
      expect(completedTask.priority, task.priority);
      expect(completedTask.createdAt, task.createdAt);
      expect(completedTask.userId, task.userId);
      expect(completedTask.courseBucket, task.courseBucket);
    });

    test('unknown priorities safely fall back to medium', () {
      expect(TaskPriorityX.fromValue('not-a-priority'), TaskPriority.medium);
      expect(TaskPriorityX.fromValue(null), TaskPriority.medium);
    });
  });
}
