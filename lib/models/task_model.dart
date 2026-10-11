import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get value => name;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromValue(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.medium;
    }
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.completed,
    required this.createdAt,
    required this.userId,
    this.courseBucket = 'CS 421',
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;
  final String userId;
  final String courseBucket;

  factory TaskModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dueDate: _timestampToDate(data['dueDate']) ?? DateTime.now(),
      priority: TaskPriorityX.fromValue(data['priority'] as String?),
      completed: data['completed'] as bool? ?? false,
      createdAt: _timestampToDate(data['createdAt']) ?? DateTime.now(),
      userId: data['userId'] as String? ?? '',
      courseBucket: data['courseBucket'] as String? ?? 'CS 421',
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.value,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'courseBucket': courseBucket,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? completed,
    String? courseBucket,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      userId: userId,
      courseBucket: courseBucket ?? this.courseBucket,
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
