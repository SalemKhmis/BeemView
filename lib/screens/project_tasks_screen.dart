import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks/tasks_cubit.dart';
import '../blocs/tasks/tasks_state.dart';
import '../config/app_theme.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../utils/date_formatters.dart';
import '../utils/status_helpers.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_badge.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

/// Project Tasks screen showing all tasks for a selected project.
///
/// Features:
/// - Search bar for local name filtering
/// - Status filter chips (labeled "Filter loaded project tasks")
/// - Task cards with name, status badge, priority badge, due date
/// - Empty state when no tasks match filters
/// - Pull-to-refresh
/// - Tap a task → navigate to Task Details
class ProjectTasksScreen extends StatefulWidget {
  final Project project;

  const ProjectTasksScreen({super.key, required this.project});

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<TasksCubit>().loadProjectTasks(widget.project.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<TasksCubit>().loadProjectTasks(widget.project.id);
    _searchController.clear();
  }

  void _onTaskTap(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
    if (mounted) {
      context.read<TasksCubit>().loadProjectTasks(widget.project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(cs, innerBoxIsScrolled),
        ],
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: cs.primary,
          child: BlocBuilder<TasksCubit, TasksState>(
            builder: (context, state) {
              if (state is TasksLoading) {
                return _buildLoading(cs);
              }
              if (state is TasksError) {
                return _buildError(cs, state.message);
              }
              if (state is TasksLoaded) {
                return _buildContent(cs, state);
              }
              return _buildLoading(cs);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(project: widget.project),
            ),
          );
          if (!context.mounted) return;
          if (result == true) {
            context.read<TasksCubit>().loadProjectTasks(widget.project.id);
          }
        },
        backgroundColor: const Color(0xFFFAAA3C),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── SliverAppBar ───────────────────────────────────────────
  SliverAppBar _buildAppBar(ColorScheme cs, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: cs.primary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Text(
          widget.project.name,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.06),
                cs.tertiary.withValues(alpha: 0.04),
                cs.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main content (search + filters + list) ─────────────────
  Widget _buildContent(ColorScheme cs, TasksLoaded state) {
    return Column(
      children: [
        // Search + filter bar
        _buildSearchAndFilters(cs, state),

        // Task count label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(
            children: [
              Text(
                '${state.filteredTasks.length} of ${state.allTasks.length} tasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              if (state.searchQuery.isNotEmpty ||
                  state.statusFilter != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    context.read<TasksCubit>().clearFilters();
                  },
                  child: Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Task list
        Expanded(
          child: state.filteredTasks.isEmpty
              ? _buildEmptyFilter(cs)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: state.filteredTasks.length,
                  itemBuilder: (context, index) => _TaskCard(
                    task: state.filteredTasks[index],
                    onTap: () => _onTaskTap(state.filteredTasks[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Search bar + status filter chips ───────────────────────
  Widget _buildSearchAndFilters(ColorScheme cs, TasksLoaded state) {
    // Collect unique statuses from loaded tasks
    final statuses =
        state.allTasks.map((t) => t.status).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: (q) => context.read<TasksCubit>().searchTasks(q),
            decoration: InputDecoration(
              hintText: 'Search tasks by name…',
              hintStyle:
                  TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () {
                        _searchController.clear();
                        context.read<TasksCubit>().searchTasks('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Label
          Text(
            'Filter loaded project tasks',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Status chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: state.statusFilter == null,
                  color: cs.primary,
                  onTap: () =>
                      context.read<TasksCubit>().filterByStatus(null),
                ),
                const SizedBox(width: 6),
                ...statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        label: StatusHelpers.statusLabel(s),
                        selected: state.statusFilter == s,
                        color: AppTheme.statusColor(s),
                        onTap: () =>
                            context.read<TasksCubit>().filterByStatus(s),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────
  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Text('Loading tasks…',
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────
  Widget _buildError(ColorScheme cs, String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded,
                    size: 36, color: cs.error.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              Text('Failed to load tasks',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context
                    .read<TasksCubit>()
                    .loadProjectTasks(widget.project.id),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty filter result ────────────────────────────────────
  Widget _buildEmptyFilter(ColorScheme cs) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.filter_list_off_rounded,
                    size: 32, color: cs.primary.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 16),
              Text('No tasks match your filters',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 6),
              Text('Try adjusting your search or status filter',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.45))),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Filter Chip Widget
// ══════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Task Card Widget
// ══════════════════════════════════════════════════════════════

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Task name + arrow
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Status + Priority badges
                Row(
                  children: [
                    StatusBadge(status: task.status, compact: true),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: task.priority, compact: true),
                  ],
                ),

                // Row 3: Due date + Assignee (if available)
                if (task.dueDate != null || task.assignees.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: _dueDateColor(cs, task.dueDate!)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatters.formatRelative(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _dueDateColor(cs, task.dueDate!),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (task.assignees.isNotEmpty) ...[
                        Icon(Icons.person_outline_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.assigneeNames,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a warning color if the due date is past or soon.
  Color _dueDateColor(ColorScheme cs, DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return cs.error; // Overdue
    }
    if (dueDate.difference(now).inDays <= 2) {
      return Colors.orange; // Due soon
    }
    return cs.onSurface.withValues(alpha: 0.45); // Normal
  }
}
