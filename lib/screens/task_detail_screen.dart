import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/task_detail/task_detail_cubit.dart';
import '../blocs/task_detail/task_detail_state.dart';
import '../config/app_theme.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../utils/date_formatters.dart';
import '../utils/status_helpers.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_badge.dart';

/// Screen 4: Task Details with modern, creative design.
///
/// Features:
/// - Header: Task name, status badge, priority badge, project pill
/// - Info section: Project name, assignees list with avatars, start/due dates, created/updated dates
/// - Description: Full text in an elevated styled card
/// - Latest comment: Most recent comment bubble (author, content, timestamp) or empty state
/// - Update Status section:
///   - Status selector with all 8 statuses and color indicators
///   - Optional note text field
///   - Save button with submission locking & loading spinner
///   - Success/error snackbar feedback + partial success retry
/// - Pull-to-refresh support
class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String? _selectedStatus;
  final _noteController = TextEditingController();
  String? _pendingNote;

  @override
  void initState() {
    super.initState();
    context.read<TaskDetailCubit>().loadTaskDetails(widget.taskId);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onSave(Task task) {
    final status = _selectedStatus ?? task.status;
    final note = _noteController.text.trim();

    context.read<TaskDetailCubit>().updateStatus(
          taskId: task.id,
          status: status,
          comment: note.isNotEmpty ? note : null,
        );

    _pendingNote = note.isNotEmpty ? note : null;
  }

  void _onRetryComment(Task task) {
    if (_pendingNote != null && _pendingNote!.isNotEmpty) {
      context.read<TaskDetailCubit>().retryComment(
            taskId: task.id,
            comment: _pendingNote!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: BlocConsumer<TaskDetailCubit, TaskDetailState>(
        listener: _stateListener,
        builder: (context, state) {
          if (state is TaskDetailLoading) {
            return _buildScaffold(cs, child: _buildLoading(cs));
          }
          if (state is TaskDetailError && state.previousTask == null) {
            return _buildScaffold(cs, child: _buildError(cs, state.message));
          }

          final task = switch (state) {
            TaskDetailLoaded s => s.task,
            TaskDetailUpdateSuccess s => s.task,
            TaskDetailError s => s.previousTask!,
            _ => null,
          };

          if (task == null) {
            return _buildScaffold(cs, child: _buildLoading(cs));
          }

          final isSubmitting =
              state is TaskDetailLoaded && state.isSubmitting;

          return _buildTaskDetail(cs, task, isSubmitting);
        },
      ),
    );
  }

  // ── State listener for user feedback ───────────────────────
  void _stateListener(BuildContext context, TaskDetailState state) {
    final cs = Theme.of(context).colorScheme;

    if (state is TaskDetailUpdateSuccess) {
      if (state.isFullSuccess) {
        _noteController.clear();
        _selectedStatus = null;
        _pendingNote = null;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Task updated successfully',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ));
        context.read<TaskDetailCubit>().acknowledgeUpdate();
      } else if (state.isPartialSuccess) {
        // Status saved but comment failed
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Status saved. Comment failed: ${state.commentError}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry Comment',
              textColor: Colors.white,
              onPressed: () => _onRetryComment(state.task),
            ),
          ));
        context.read<TaskDetailCubit>().acknowledgeUpdate();
      }
    }

    if (state is TaskDetailError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
    }
  }

  // ── Scaffold wrapper for simple states ─────────────────────
  Widget _buildScaffold(ColorScheme cs, {required Widget child}) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Task Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: cs.onSurface,
            ),
          ),
          leading: _buildBackButton(cs),
        ),
        SliverFillRemaining(child: child),
      ],
    );
  }

  Widget _buildBackButton(ColorScheme cs) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: cs.primary,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  // ── Full Task Detail Layout ────────────────────────────────
  Widget _buildTaskDetail(ColorScheme cs, Task task, bool isSubmitting) {
    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read<TaskDetailCubit>()
            .refreshTaskDetails(widget.taskId);
      },
      color: cs.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Elegant Header Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            leading: _buildBackButton(cs),
            title: Text(
              'Task #${task.id}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: cs.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                tooltip: 'Refresh',
                onPressed: () => context
                    .read<TaskDetailCubit>()
                    .refreshTaskDetails(widget.taskId),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Header Card: Task Name & Badges
                _buildHeaderCard(cs, task),
                const SizedBox(height: 16),

                // 2. Info Section (Grid cards for project, assignees, dates)
                _buildInfoGrid(cs, task),
                const SizedBox(height: 16),

                // 3. Description Section
                _buildDescriptionSection(cs, task),
                const SizedBox(height: 16),

                // 4. Latest Comment Section
                _buildLatestCommentSection(cs, task),
                const SizedBox(height: 20),

                // Section Separator
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(
                            'TASK ACTIONS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Update Status Section
                _buildUpdateStatusCard(cs, task, isSubmitting),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header Card ────────────────────────────────────────────
  Widget _buildHeaderCard(ColorScheme cs, Task task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project pill tag
          if (task.project != null && task.project!.name.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E96BE).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 13, color: Color(0xFF1E96BE)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      task.project!.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E96BE),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Task Name
          Text(
            task.name,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status: task.status),
              PriorityBadge(priority: task.priority),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info Grid ──────────────────────────────────────────────
  Widget _buildInfoGrid(ColorScheme cs, Task task) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'done' &&
        task.status != 'canceled';

    return Column(
      children: [
        // Row 1: Project & Assignees
        Row(
          children: [
            Expanded(
              child: _DetailInfoTile(
                icon: Icons.business_center_rounded,
                iconColor: const Color(0xFF1E96BE),
                title: 'Project',
                value: task.project?.name.isNotEmpty == true
                    ? task.project!.name
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AssigneesTile(
                assignees: task.assignees,
                fallbackText: task.assigneeNames,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Start Date & Due Date
        Row(
          children: [
            Expanded(
              child: _DetailInfoTile(
                icon: Icons.play_circle_outline_rounded,
                iconColor: const Color(0xFF00897B),
                title: 'Start Date',
                value: DateFormatters.formatDate(task.startDate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailInfoTile(
                icon: Icons.event_rounded,
                iconColor: isOverdue
                    ? const Color(0xFFE53935)
                    : const Color(0xFFFB8C00),
                title: 'Due Date',
                value: DateFormatters.formatDate(task.dueDate),
                badgeText: isOverdue ? 'Overdue' : null,
                badgeColor: const Color(0xFFE53935),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Created & Updated Dates
        Row(
          children: [
            Expanded(
              child: _DetailInfoTile(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF5C6BC0),
                title: 'Created At',
                value: DateFormatters.formatDate(task.createdAt),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DetailInfoTile(
                icon: Icons.update_rounded,
                iconColor: const Color(0xFF7E57C2),
                title: 'Last Updated',
                value: DateFormatters.formatDate(task.updatedAt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Description Section ────────────────────────────────────
  Widget _buildDescriptionSection(ColorScheme cs, Task task) {
    final hasDescription =
        task.description != null && task.description!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E96BE).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: Color(0xFF1E96BE),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDescription)
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            )
          else
            Text(
              'No description provided for this task.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }

  // ── Latest Comment Section ─────────────────────────────────
  Widget _buildLatestCommentSection(ColorScheme cs, Task task) {
    final comment = task.latestComment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: comment != null
              ? const Color(0xFF1E96BE).withValues(alpha: 0.2)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E96BE).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 16,
                  color: Color(0xFF1E96BE),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Latest Comment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (comment != null && task.comments.length > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${task.comments.length} comments',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (comment != null) ...[
            // Author + Date Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1E96BE),
                  child: Text(
                    (comment.user?.fullName.isNotEmpty == true
                            ? comment.user!.fullName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user?.fullName ?? 'Unknown Author',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        DateFormatters.formatDateTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Speech bubble content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE3E8F5),
                  width: 1,
                ),
              ),
              child: Text(
                comment.content,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No comments yet on this task',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Update Status Section ──────────────────────────────────
  Widget _buildUpdateStatusCard(
      ColorScheme cs, Task task, bool isSubmitting) {
    _selectedStatus ??= task.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E96BE).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E96BE).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E5A73), Color(0xFF1E96BE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.published_with_changes_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Select a new status and optionally leave a note',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Selector Dropdown
          Text(
            'TARGET STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(14),
                dropdownColor: cs.surface,
                items: StatusHelpers.allStatuses.map((s) {
                  final color = AppTheme.statusColor(s);
                  final isCurrent = s == task.status;
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            StatusHelpers.statusLabel(s),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Note text field
          Text(
            'OPTIONAL NOTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _noteController,
            maxLines: 3,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Add a comment or update reason…',
              hintStyle: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E4EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 22),

          // Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => _onSave(task),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E96BE),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF1E96BE).withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                elevation: isSubmitting ? 0 : 3,
                shadowColor: const Color(0xFF1E96BE).withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Saving changes…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────
  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading task details…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────
  Widget _buildError(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: cs.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Failed to load task',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context
                  .read<TaskDetailCubit>()
                  .loadTaskDetails(widget.taskId),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Reusable Detail Info Tile
// ══════════════════════════════════════════════════════════════

class _DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? badgeText;
  final Color? badgeColor;

  const _DetailInfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Assignees Tile with Interactive Avatar bubbles
// ══════════════════════════════════════════════════════════════

class _AssigneesTile extends StatelessWidget {
  final List<User> assignees;
  final String fallbackText;

  const _AssigneesTile({
    required this.assignees,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const iconColor = Color(0xFF00897B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Assignees',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (assignees.isNotEmpty)
            Row(
              children: [
                // Overlapping avatar circles
                SizedBox(
                  height: 24,
                  width: (20.0 * (assignees.length > 3 ? 3 : assignees.length)) + 4,
                  child: Stack(
                    children: List.generate(
                      assignees.length > 3 ? 3 : assignees.length,
                      (i) => Positioned(
                        left: i * 16.0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: [
                            const Color(0xFF1E88E5),
                            const Color(0xFF43A047),
                            const Color(0xFF8E24AA),
                          ][i % 3],
                          child: Text(
                            assignees[i].fullName.isNotEmpty
                                ? assignees[i].fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fallbackText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              'Unassigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}
