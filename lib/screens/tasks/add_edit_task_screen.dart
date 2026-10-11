import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_style.dart';
import '../../utils/date_utils.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({super.key, this.task});

  static const String routeName = '/add-task';

  final TaskModel? task;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _dueDate;
  TaskPriority _priority = TaskPriority.low;
  String _courseBucket = 'CS 421';
  bool _completed = false;
  bool _saving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _loadTaskValues();
  }

  void _loadTaskValues() {
    final task = widget.task;
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? TaskPriority.low;
    _courseBucket = task?.courseBucket ?? 'CS 421';
    _completed = task?.completed ?? false;
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(_loadTaskValues);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.task == null) {
        await FirestoreService.instance.addTask(
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          priority: _priority,
          courseBucket: _courseBucket,
        );
      } else {
        await FirestoreService.instance.updateTask(
          widget.task!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            dueDate: _dueDate,
            priority: _priority,
            completed: _completed,
            courseBucket: _courseBucket,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showMessage(
        'Could not save the task. Check your connection and try again.',
      );
      debugPrint('Save task error: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _dueDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Due Date'),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDueDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatShortDate(_dueDate),
                    style: const TextStyle(fontSize: 10, color: AppColors.ink),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> get _courseBuckets {
    final buckets = <String>['CS 421', 'General'];
    if (!buckets.contains(_courseBucket)) buckets.insert(0, _courseBucket);
    return buckets;
  }

  Widget _courseBucketField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Course Bucket'),
        const SizedBox(height: 6),
        Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _courseBucket,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: const TextStyle(fontSize: 10, color: AppColors.ink),
              items: _courseBuckets.map((bucket) {
                return DropdownMenuItem<String>(
                  value: bucket,
                  child: Text('●  $bucket', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _courseBucket = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Task' : 'New Task',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: isEditing
                        ? TextButton(
                            onPressed: _saving ? null : _resetForm,
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  children: [
                    FieldLabel(
                      'Task Title',
                      trailing: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _titleController,
                        builder: (context, value, _) => Text(
                          '${value.text.length}/60',
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'e.g. Complete Flutter Assignment',
                        counterText: '',
                        suffixIcon: isEditing
                            ? IconButton(
                                onPressed: _titleController.clear,
                                icon: const Icon(Icons.close_rounded, size: 15),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Task title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),
                    const FieldLabel('Description & Milestones'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add details, links, or notes...',
                        alignLabelWithHint: true,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 17),
                    if (isEditing)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _dueDateField()),
                          const SizedBox(width: 10),
                          Expanded(child: _courseBucketField()),
                        ],
                      )
                    else
                      _dueDateField(),
                    const SizedBox(height: 17),
                    const FieldLabel('Priority'),
                    const SizedBox(height: 7),
                    Row(
                      children: TaskPriority.values.map((priority) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: priority == TaskPriority.high ? 0 : 7,
                            ),
                            child: _PriorityOption(
                              priority: priority,
                              selected: _priority == priority,
                              onTap: () => setState(() => _priority = priority),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _completed
                                        ? 'Task is done'
                                        : 'Mark task as done',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _completed,
                              activeTrackColor: AppColors.purple,
                              onChanged: (value) =>
                                  setState(() => _completed = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 43,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _saveTask,
                        style: FilledButton.styleFrom(
                          backgroundColor: isEditing
                              ? AppColors.navy
                              : AppColors.purple,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEditing ? '✓  Save Changes' : 'Save Task'),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = PriorityColors.forName(priority.value);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              priority.label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
