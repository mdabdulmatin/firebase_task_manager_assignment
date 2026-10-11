import 'package:flutter/material.dart';

import 'models/task_model.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/tasks/add_edit_task_screen.dart';
import 'screens/tasks/task_details_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_style.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Task Manager',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: buildAppTheme(),
      routes: {
        '/': (_) => const AuthGate(),
        TaskListScreen.routeName: (_) => const TaskListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AddEditTaskScreen.routeName) {
          final task = settings.arguments;
          return MaterialPageRoute<void>(
            builder: (_) =>
                AddEditTaskScreen(task: task is TaskModel ? task : null),
          );
        }

        if (settings.name == TaskDetailsScreen.routeName) {
          final argument = settings.arguments;
          if (argument is String) {
            return MaterialPageRoute<void>(
              builder: (_) => TaskDetailsScreen(taskId: argument),
            );
          }
        }

        return null;
      },
    );
  }
}
