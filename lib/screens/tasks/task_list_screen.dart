import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_style.dart';
import '../../widgets/delete_task_dialog.dart';
import 'add_edit_task_screen.dart';
import 'task_card.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  static const String routeName = '/tasks';

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  String _query = '';
  String _statusFilter = 'all';
  TaskPriority? _priorityFilter;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _query = _searchController.text.trim().toLowerCase());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingTaskId = NotificationService.instance.consumePendingTaskId();
      if (pendingTaskId != null && mounted) {
        Navigator.pushNamed(
          context,
          TaskDetailsScreen.routeName,
          arguments: pendingTaskId,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await AuthService.instance.signOut();
    } catch (error) {
      _showMessage('Could not sign out. Please try again.');
      debugPrint('Sign out error: $error');
    }
  }

  Future<void> _openCreateTask() async {
    await Navigator.pushNamed(context, AddEditTaskScreen.routeName);
  }

  Future<void> _openEditTask(TaskModel task) async {
    await Navigator.pushNamed(
      context,
      AddEditTaskScreen.routeName,
      arguments: task,
    );
  }

  Future<void> _toggleTask(TaskModel task) async {
    try {
      await FirestoreService.instance.setTaskCompleted(
        task.id,
        !task.completed,
      );
    } catch (error) {
      _showMessage('Could not update this task. Check your connection.');
      debugPrint('Task completion error: $error');
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDeleteTaskDialog(context, task);
    if (!confirmed) return;

    try {
      await FirestoreService.instance.deleteTask(task.id);
      _showMessage('Task deleted.');
    } catch (error) {
      _showMessage('Could not delete this task. Please try again.');
      debugPrint('Delete task error: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showFilters() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        const options = <(int, String)>[
          (0, 'All priorities'),
          (1, 'Low priority'),
          (2, 'Medium priority'),
          (3, 'High priority'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by priority',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final optionPriority = switch (option.$1) {
                    1 => TaskPriority.low,
                    2 => TaskPriority.medium,
                    3 => TaskPriority.high,
                    _ => null,
                  };
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.$2,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: _priorityFilter == optionPriority
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.purple,
                          )
                        : null,
                    onTap: () => Navigator.pop(sheetContext, option.$1),
                  );
                }),
                const Divider(height: 18),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded, size: 19),
                  title: const Text('Sign out', style: TextStyle(fontSize: 13)),
                  onTap: () => Navigator.pop(sheetContext, 4),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == 4) {
      await _logout();
      return;
    }
    if (choice != null) {
      setState(() {
        _priorityFilter = switch (choice) {
          1 => TaskPriority.low,
          2 => TaskPriority.medium,
          3 => TaskPriority.high,
          _ => null,
        };
      });
    }
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks
        .where((task) {
          final matchesSearch =
              _query.isEmpty ||
              task.title.toLowerCase().contains(_query) ||
              task.description.toLowerCase().contains(_query);
          final matchesStatus =
              _statusFilter == 'all' ||
              (_statusFilter == 'pending' && !task.completed) ||
              (_statusFilter == 'completed' && task.completed);
          final matchesPriority =
              _priorityFilter == null || task.priority == _priorityFilter;
          return matchesSearch && matchesStatus && matchesPriority;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: FirestoreService.instance.watchTasks(),
          builder: (context, snapshot) {
            final allTasks = snapshot.data ?? const <TaskModel>[];
            final pendingCount = allTasks
                .where((task) => !task.completed)
                .length;
            final completedCount = allTasks
                .where((task) => task.completed)
                .length;
            final visibleTasks = _filterTasks(allTasks);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF0F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${allTasks.length} TOTAL',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) _searchController.clear();
                        }),
                        icon: Icon(
                          _showSearch
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 19,
                        ),
                        color: AppColors.muted,
                        tooltip: 'Search tasks',
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded, size: 19),
                        color: _priorityFilter == null
                            ? AppColors.muted
                            : AppColors.purple,
                        tooltip: 'Filter tasks',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today • ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search tasks',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded, size: 17),
                              ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'All',
                        count: allTasks.length,
                        selected: _statusFilter == 'all',
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                      const SizedBox(width: 7),
                      _StatusChip(
                        label: 'Pending',
                        count: pendingCount,
                        selected: _statusFilter == 'pending',
                        onTap: () => setState(() => _statusFilter = 'pending'),
                      ),
                      const SizedBox(width: 7),
                      _StatusChip(
                        label: 'Completed',
                        count: completedCount,
                        selected: _statusFilter == 'completed',
                        onTap: () =>
                            setState(() => _statusFilter = 'completed'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildTaskContent(snapshot, visibleTasks)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 17),
        label: const Text('New Task', style: TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildTaskContent(
    AsyncSnapshot<List<TaskModel>> snapshot,
    List<TaskModel> tasks,
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load tasks.\n${snapshot.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red, fontSize: 12),
          ),
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      },
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(35, 65, 35, 100),
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 42,
                  color: Colors.blueGrey.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  _query.isEmpty ? 'No tasks yet' : 'No matching tasks',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a task to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              itemCount: tasks.length,
              // ignore: unnecessary_underscores
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () => Navigator.pushNamed(
                    context,
                    TaskDetailsScreen.routeName,
                    arguments: task.id,
                  ),
                  onToggle: () => _toggleTask(task),
                  onEdit: () => _openEditTask(task),
                  onDelete: () => _deleteTask(task),
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white24 : const Color(0xFFF0F2F6),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
