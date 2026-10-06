import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/create_task/create_task_cubit.dart';
import '../blocs/create_task/create_task_state.dart';
import '../config/app_theme.dart';
import '../data/repositories/task_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';

/// Screen for creating a new task.
///
/// Features:
/// - Name, description, status, priority, dates inputs
/// - Optional project assignment (pre-filled when launched from a project)
/// - Privacy toggle
/// - Form validation
/// - Loading state during submission
/// - Success/error feedback via SnackBar
class AddTaskScreen extends StatefulWidget {
  /// If provided, the task will be pre-assigned to this project.
  final Project? project;

  const AddTaskScreen({super.key, this.project});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'to_do';
  String _selectedPriority = 'medium';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isPrivate = false;

  static const List<_StatusOption> _statusOptions = [
    _StatusOption('to_do', 'To Do', Icons.radio_button_unchecked_rounded),
    _StatusOption(
        'in_progress', 'In Progress', Icons.play_circle_outline_rounded),
    _StatusOption('on_hold', 'On Hold', Icons.pause_circle_outline_rounded),
    _StatusOption('review', 'Review', Icons.rate_review_outlined),
    _StatusOption('done', 'Done', Icons.check_circle_outline_rounded),
    _StatusOption('canceled', 'Canceled', Icons.cancel_outlined),
  ];

  static const List<_PriorityOption> _priorityOptions = [
    _PriorityOption('low', 'Low', Icons.arrow_downward_rounded),
    _PriorityOption('medium', 'Medium', Icons.remove_rounded),
    _PriorityOption('high', 'High', Icons.arrow_upward_rounded),
    _PriorityOption('urgent', 'Urgent', Icons.priority_high_rounded),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial =
        isStart ? (_startDate ?? now) : (_dueDate ?? _startDate ?? now);
    final firstDate = isStart ? DateTime(2020) : (_startDate ?? DateTime(2020));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_dueDate != null && _dueDate!.isBefore(picked)) {
            _dueDate = null;
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final dateFormat = DateFormat('yyyy-MM-dd');
    context.read<CreateTaskCubit>().createTask(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          status: _selectedStatus,
          priority: _selectedPriority,
          startDate:
              _startDate != null ? dateFormat.format(_startDate!) : null,
          dueDate: _dueDate != null ? dateFormat.format(_dueDate!) : null,
          projectId: widget.project?.id,
          isPrivate: _isPrivate,
          assignees: const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => CreateTaskCubit(
        taskRepository: RepositoryProvider.of<TaskRepository>(context),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.close_rounded, size: 18, color: cs.primary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                context.tr('create_task_title'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: cs.onSurface,
                ),
              ),
            ),
            body: BlocListener<CreateTaskCubit, CreateTaskState>(
              listener: (context, state) {
                if (state is CreateTaskSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(context.tr('task_created')),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pop(context, true); // true = refresh list
                } else if (state is CreateTaskError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(state.message)),
                        ],
                      ),
                      backgroundColor: cs.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header illustration ──
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.secondaryColor
                                    .withValues(alpha: 0.15),
                                AppTheme.primaryColor
                                    .withValues(alpha: 0.10),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
                            size: 34,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Project context chip ──
                      if (widget.project != null)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_rounded,
                                    size: 15, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  widget.project!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // ── Task Name ──
                      _buildLabel(context.tr('task_name'), isRequired: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: context.tr('task_name_hint'),
                          prefixIcon: Icon(Icons.task_alt_rounded,
                              color: cs.primary.withValues(alpha: 0.6)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return context.tr('field_required');
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Description ──
                      _buildLabel(context.tr('description')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: context.tr('description_hint'),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.description_rounded,
                                color: cs.primary.withValues(alpha: 0.6)),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Status & Priority Row ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context.tr('status'), isRequired: true),
                                const SizedBox(height: 8),
                                _buildStatusDropdown(cs),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context.tr('priority_label'), isRequired: true),
                                const SizedBox(height: 8),
                                _buildPrioritySelector(cs),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Dates Row ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context.tr('start_date')),
                                const SizedBox(height: 8),
                                _buildDateButton(
                                    cs, _startDate, context.tr('select_start_date'), true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context.tr('due_date')),
                                const SizedBox(height: 8),
                                _buildDateButton(
                                    cs, _dueDate, context.tr('select_due_date'), false),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Private Toggle ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPrivate
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 20,
                              color: _isPrivate
                                  ? AppTheme.secondaryColor
                                  : cs.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('is_private'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    context.tr('private_task_hint'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isPrivate,
                              onChanged: (v) =>
                                  setState(() => _isPrivate = v),
                              activeTrackColor: AppTheme.secondaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Submit Button ──
                      BlocBuilder<CreateTaskCubit, CreateTaskState>(
                        builder: (context, state) {
                          final isLoading = state is CreateTaskSubmitting;
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed:
                                  isLoading ? null : () => _submit(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTheme
                                    .secondaryColor
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                                shadowColor: AppTheme.secondaryColor
                                    .withValues(alpha: 0.4),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_rounded, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.tr('create_task_btn'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(color: Color(0xFFF44336), fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildStatusDropdown(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        items: _statusOptions.map((opt) {
          return DropdownMenuItem(
            value: opt.value,
            child: Row(
              children: [
                Icon(opt.icon, size: 16, color: AppTheme.statusColor(opt.value)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedStatus = v);
        },
      ),
    );
  }

  Widget _buildPrioritySelector(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPriority,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        items: _priorityOptions.map((opt) {
          return DropdownMenuItem(
            value: opt.value,
            child: Row(
              children: [
                Icon(opt.icon,
                    size: 16, color: AppTheme.priorityColor(opt.value)),
                const SizedBox(width: 8),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedPriority = v);
        },
      ),
    );
  }

  Widget _buildDateButton(
      ColorScheme cs, DateTime? date, String hint, bool isStart) {
    final formatted =
        date != null ? DateFormat('MMM dd, yyyy').format(date) : null;

    return InkWell(
      onTap: () => _pickDate(context, isStart),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: date != null
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formatted ?? hint,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                  color: date != null
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  final String value;
  final String label;
  final IconData icon;

  const _StatusOption(this.value, this.label, this.icon);
}

class _PriorityOption {
  final String value;
  final String label;
  final IconData icon;

  const _PriorityOption(this.value, this.label, this.icon);
}
