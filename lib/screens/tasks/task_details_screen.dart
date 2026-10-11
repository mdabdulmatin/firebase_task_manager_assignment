import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_style.dart';
import '../../utils/date_utils.dart';
import '../../widgets/delete_task_dialog.dart';
import 'add_edit_task_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  static const String routeName = '/task-details';

  final String taskId;

  Future<void> _deleteTask(BuildContext context, TaskModel task) async {
    final confirmed = await showDeleteTaskDialog(context, task);
    if (!confirmed) return;
    try {
      await FirestoreService.instance.deleteTask(task.id);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this task. Try again.')),
      );
      debugPrint('Delete task error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<TaskModel?>(
          stream: FirestoreService.instance.watchTask(taskId),
          builder: (context, snapshot) {
            final task = snapshot.data;
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 19),
                      ),
                      const Expanded(
                        child: Text(
                          'Task Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: task == null
                            ? const SizedBox.shrink()
                            : PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  size: 19,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.pushNamed(
                                      context,
                                      AddEditTaskScreen.routeName,
                                      arguments: task,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteTask(context, task);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit task'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete task'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: snapshot.hasError
                      ? const Center(child: Text('Unable to load this task.'))
                      : snapshot.connectionState == ConnectionState.waiting
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : task == null
                      ? const Center(child: Text('Task not found.'))
                      : _TaskDetailsBody(task: task),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskDetailsBody extends StatelessWidget {
  const _TaskDetailsBody({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final priorityColor = PriorityColors.forName(task.priority.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  task.completed
                      ? Icons.check_rounded
                      : Icons.assignment_outlined,
                  color: AppColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.completed ? 'Completed' : 'In progress',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.completed
                          ? 'This task is done.'
                          : 'Keep going and finish this task.',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          task.description.isEmpty ? 'No description added.' : task.description,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.muted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        _DetailRow(
          label: 'Due date',
          value: formatShortDate(task.dueDate),
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 9),
        _DetailRow(
          label: 'Course bucket',
          value: task.courseBucket,
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 9),
        _DetailRow(
          label: 'Priority',
          value: task.priority.label,
          icon: Icons.flag_outlined,
          valueColor: priorityColor,
        ),
        const SizedBox(height: 9),
        _DetailRow(
          label: 'Created',
          value: formatTaskDateTime(task.createdAt),
          icon: Icons.schedule_outlined,
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            onPressed: () async {
              try {
                await FirestoreService.instance.setTaskCompleted(
                  task.id,
                  !task.completed,
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not update task status.'),
                  ),
                );
                debugPrint('Update completion error: $error');
              }
            },
            child: Text(
              task.completed ? 'Mark as Pending' : 'Mark as Completed',
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(
            context,
            AddEditTaskScreen.routeName,
            arguments: task,
          ),
          child: const Text('Edit Task'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
