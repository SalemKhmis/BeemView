import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/dashboard/dashboard_cubit.dart';
import '../blocs/dashboard/dashboard_state.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/dashboard_analytics.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'add_project_screen.dart';
import 'add_task_screen.dart';
import 'project_tasks_screen.dart';
import 'task_detail_screen.dart';

/// Screen: Executive Home Dashboard with Real-Time Analytics
///
/// Features:
/// - Real-time Workspace Health Score indicator
/// - Live KPI Metrics (Total Projects, Tasks Done, Completion Rate)
/// - Quick Action Bar (+ New Project, + New Task)
/// - Visual Task Distribution Bar (To Do, In Progress, Review, Done)
/// - Urgent & Upcoming Deadlines attention card
/// - Active Projects Carousel with progress indicators
/// - Smooth Pull-to-Refresh
class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToProjects;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    required this.onNavigateToProjects,
    this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  Future<void> _refresh() async {
    await context.read<DashboardCubit>().loadDashboard();
  }

  String _getTimeGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('good_morning');
    if (hour < 17) return context.tr('good_afternoon');
    return context.tr('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Retrieve authenticated user
    final authState = context.watch<AuthCubit>().state;
    final User? currentUser = authState is AuthAuthenticated ? authState.user : null;
    final userName = currentUser?.fullName ?? 'Team Member';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Top App Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: _buildHeader(context, cs, userName),
                ),
              ),

              // 2. Main Dashboard Content
              BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('aggregating_analytics'),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is DashboardError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  size: 48, color: cs.error),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(context.tr('try_again')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is DashboardLoaded) {
                    final analytics = state.analytics;
                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero Analytics Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildRealTimeHeroCard(cs, analytics),
                        ),
                        const SizedBox(height: 18),

                        // Quick Actions Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildQuickActions(context, cs),
                        ),
                        const SizedBox(height: 22),

                        // Task Distribution & Velocity
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTaskDistributionCard(cs, analytics),
                        ),
                        const SizedBox(height: 24),

                        // Requires Attention (Urgent & Upcoming Deadlines)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildAttentionSection(context, cs, analytics),
                        ),
                        const SizedBox(height: 24),

                        // Active Projects Carousel
                        _buildActiveProjectsSection(context, cs, analytics),
                        const SizedBox(height: 36),
                      ]),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Header ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ColorScheme cs, String userName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Avatar / Logo Icon (tap to view profile)
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToProfile,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cs.surfaceContainerHigh,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/beemview_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.dashboard_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Greeting and Workspace Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getTimeGreeting(context)},',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Theme Switcher (Light / Dark)
        const ThemeToggleButton(isCompact: true),
        const SizedBox(width: 8),

        // Language Switcher (EN / العربية)
        const LanguageToggleButton(isCompact: true),
        const SizedBox(width: 4),

        // Logout Action
        IconButton(
          onPressed: () => _showLogoutDialog(cs),
          icon: Icon(Icons.logout_rounded, color: cs.onSurfaceVariant),
          tooltip: context.tr('logout'),
        ),
      ],
    );
  }

  void _showLogoutDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('logout'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          context.tr('logout_confirm'),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().logout();
            },
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  // ── 2. Real-Time Hero Card ────────────────────────────────────
  Widget _buildRealTimeHeroCard(ColorScheme cs, DashboardAnalytics analytics) {
    final health = analytics.healthScore;
    final healthLabel = health >= 85
        ? context.tr('optimal')
        : health >= 70
            ? context.tr('on_track')
            : context.tr('needs_focus');
    final healthColor = health >= 85
        ? const Color(0xFF34D399) // Emerald
        : health >= 70
            ? const Color(0xFFFBBF24) // Amber
            : const Color(0xFFF87171); // Rose

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A4B60), // Dark Teal
            Color(0xFF167B9E), // BeemView Teal
            Color(0xFF1E96BE), // BeemView Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row: Real-time Analytics Header + Overview 360 Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('real_time_analytics'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  context.tr('overview_360'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Stats Row
          Row(
            children: [
              // Health Score Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: health / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$health%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        context.tr('health_score'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // KPI Counters Grid
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildKpiItem(
                      label: context.tr('projects'),
                      value: '${analytics.totalProjects}',
                      subLabel: '${analytics.projectSummaries.length} ${context.tr('active')}',
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    _buildKpiItem(
                      label: context.tr('tasks'),
                      value: '${analytics.totalTasks}',
                      subLabel: '${analytics.completedTasks} ${context.tr('done')}',
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    _buildKpiItem(
                      label: context.tr('velocity'),
                      value: '${analytics.completionRate.toStringAsFixed(0)}%',
                      subLabel: healthLabel,
                      highlightColor: healthColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required String subLabel,
    Color? highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 3. Quick Actions ──────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, ColorScheme cs) {
    return Row(
      children: [
        // Add Project Button
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.create_new_folder_rounded,
            label: context.tr('new_project'),
            color: AppTheme.primaryColor,
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddProjectScreen()),
              );
              if (result == true && mounted) {
                _refresh();
              }
            },
          ),
        ),
        const SizedBox(width: 12),

        // Add Task Button
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.add_task_rounded,
            label: context.tr('new_task'),
            color: AppTheme.secondaryColor,
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddTaskScreen()),
              );
              if (result == true && mounted) {
                _refresh();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 4. Task Distribution & Velocity ───────────────────────────
  Widget _buildTaskDistributionCard(
      ColorScheme cs, DashboardAnalytics analytics) {
    final total = analytics.totalTasks;
    final todo = analytics.todoTasks;
    final inProgress = analytics.inProgressTasks;
    final review = analytics.reviewTasks;
    final done = analytics.completedTasks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.donut_large_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('task_distribution'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '$total ${context.tr('total')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-segmented Distribution Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? Container(color: cs.surfaceContainerHigh)
                  : Row(
                      children: [
                        if (done > 0)
                          Expanded(
                            flex: done,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                        if (inProgress > 0)
                          Expanded(
                            flex: inProgress,
                            child: Container(color: AppTheme.primaryColor),
                          ),
                        if (review > 0)
                          Expanded(
                            flex: review,
                            child: Container(color: const Color(0xFF8B5CF6)),
                          ),
                        if (todo > 0)
                          Expanded(
                            flex: todo,
                            child: Container(color: const Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Detailed Status Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPill(context.tr('status_done'), done, const Color(0xFF10B981)),
              _buildStatusPill(context.tr('in_progress'), inProgress, AppTheme.primaryColor),
              _buildStatusPill(context.tr('review'), review, const Color(0xFF8B5CF6)),
              _buildStatusPill(context.tr('to_do'), todo, const Color(0xFF94A3B8)),
            ],
          ),

          if (analytics.urgentTasks > 0 || analytics.highPriorityTasks > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('high_priority_work'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (analytics.urgentTasks > 0) ...[
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${analytics.urgentTasks} ${context.tr('urgent')}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
                if (analytics.highPriorityTasks > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${analytics.highPriorityTasks} ${context.tr('high')}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 5. Requires Attention (Urgent & Deadlines) ─────────────────
  Widget _buildAttentionSection(
      BuildContext context, ColorScheme cs, DashboardAnalytics analytics) {
    final tasks = analytics.attentionTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('requires_attention'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            if (tasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length} ${context.tr('pending')}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.error,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('workspace_healthy'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map((task) => _buildAttentionTaskItem(context, cs, task)),
      ],
    );
  }

  Widget _buildAttentionTaskItem(
      BuildContext context, ColorScheme cs, Task task) {
    final isUrgent = task.priority.toLowerCase() == 'urgent';
    final hasDueDate = task.dueDate != null;
    final isOverdue = hasDueDate &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUrgent
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : AppTheme.secondaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUrgent ? Icons.priority_high_rounded : Icons.schedule_rounded,
            color: isUrgent ? const Color(0xFFEF4444) : AppTheme.secondaryColor,
            size: 18,
          ),
        ),
        title: Text(
          task.name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (task.project != null) ...[
              Text(
                task.project!.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(' • ', style: TextStyle(fontSize: 10)),
            ],
            if (hasDueDate)
              Text(
                DateFormat('MMM d').format(task.dueDate!),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? cs.error : cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ── 6. Active Projects Carousel ───────────────────────────────
  Widget _buildActiveProjectsSection(
      BuildContext context, ColorScheme cs, DashboardAnalytics analytics) {
    final summaries = analytics.projectSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('active_initiatives'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToProjects,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (summaries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  context.tr('no_initiatives'),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return _buildProjectCard(context, cs, summary);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProjectCard(
      BuildContext context, ColorScheme cs, ProjectSummary summary) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectTasksScreen(project: summary.project),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.project.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${summary.doneTasks}/${summary.totalTasks} ${context.tr('status_done')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      '${(summary.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: summary.progress,
                    backgroundColor: cs.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
