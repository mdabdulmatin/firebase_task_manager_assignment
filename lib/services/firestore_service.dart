import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasks {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to manage tasks.');
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  Stream<List<TaskModel>> watchTasks() {
    return _tasks
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TaskModel.fromDocument).toList(growable: false),
        );
  }

  Stream<TaskModel?> watchTask(String taskId) {
    return _tasks.doc(taskId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TaskModel.fromDocument(doc);
    });
  }

  Future<TaskModel?> getTask(String taskId) async {
    final doc = await _tasks.doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromDocument(doc);
  }

  Future<String> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskPriority priority,
    String courseBucket = 'CS 421',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to manage tasks.');

    final doc = _tasks.doc();
    await doc.set(<String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.value,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'courseBucket': courseBucket,
    });
    return doc.id;
  }

  Future<void> updateTask(TaskModel task) {
    return _tasks.doc(task.id).update(<String, dynamic>{
      'title': task.title.trim(),
      'description': task.description.trim(),
      'dueDate': Timestamp.fromDate(task.dueDate),
      'priority': task.priority.value,
      'completed': task.completed,
      'courseBucket': task.courseBucket,
    });
  }

  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();

  Future<void> setTaskCompleted(String taskId, bool completed) {
    return _tasks.doc(taskId).update(<String, dynamic>{'completed': completed});
  }
}
