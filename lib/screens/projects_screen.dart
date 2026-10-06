import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/projects/projects_cubit.dart';
import '../blocs/projects/projects_state.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'add_project_screen.dart';
import 'project_tasks_screen.dart';

/// Projects list screen with:
/// - Paginated project cards (load more)
/// - Pull-to-refresh
/// - Loading / empty / error states
/// - Logout action
/// - Tap to navigate to project tasks
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectsCubit>().loadProjects();
  }

  Future<void> _onRefresh() async {
    await context.read<ProjectsCubit>().loadProjects();
  }

  void _onProjectTap(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectTasksScreen(project: project),
      ),
    );
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
          child: BlocBuilder<ProjectsCubit, ProjectsState>(
            builder: (context, state) {
              if (state is ProjectsLoading) {
                return _buildLoading(cs);
              }
              if (state is ProjectsError) {
                return _buildError(cs, state.message);
              }
              if (state is ProjectsLoaded) {
                if (state.projects.isEmpty) {
                  return _buildEmpty(cs);
                }
                return _buildProjectList(cs, state);
              }
              if (state is ProjectsLoadingMore) {
                return _buildProjectList(
                  cs,
                  null,
                  projects: state.currentProjects,
                  isLoadingMore: true,
                );
              }
              return _buildLoading(cs);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddProjectScreen()),
          );
          if (!context.mounted) return;
          if (result == true) {
            context.read<ProjectsCubit>().loadProjects();
          }
        },
        backgroundColor: const Color(0xFF1E96BE),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          context.tr('new_project'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── SliverAppBar ───────────────────────────────────────────
  SliverAppBar _buildAppBar(ColorScheme cs, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/beemview_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('projects'),
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E96BE).withValues(alpha: 0.12),
                const Color(0xFFFAAA3C).withValues(alpha: 0.08),
                cs.surface,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
      actions: [
        // Theme Toggle
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ThemeToggleButton(isCompact: true),
        ),
        const SizedBox(width: 4),
        // Language Toggle
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LanguageToggleButton(isCompact: true),
        ),
        // Logout
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 4),
          child: IconButton(
            onPressed: () => _showLogoutDialog(cs),
            icon: Icon(Icons.logout_rounded, color: cs.onSurfaceVariant),
            tooltip: context.tr('logout'),
          ),
        ),
      ],
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
              strokeWidth: 3,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading projects…',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────
  Widget _buildEmpty(ColorScheme cs) {
    return ListView(
      // ListView so pull-to-refresh works on empty state
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_off_outlined,
                    size: 40, color: cs.primary.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Text(
                'No Projects Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────
  Widget _buildError(ColorScheme cs, String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded,
                    size: 40, color: cs.error.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.read<ProjectsCubit>().loadProjects(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
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
      ],
    );
  }

  // ── Project list ───────────────────────────────────────────
  Widget _buildProjectList(
    ColorScheme cs,
    ProjectsLoaded? loadedState, {
    List<Project>? projects,
    bool isLoadingMore = false,
  }) {
    final items = projects ?? loadedState!.projects;
    final hasMore = loadedState?.hasMore ?? false;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more button / loading indicator at the bottom
        if (index == items.length) {
          return _buildLoadMoreButton(cs, isLoadingMore);
        }
        return _ProjectCard(
          project: items[index],
          index: index,
          onTap: () => _onProjectTap(items[index]),
        );
      },
    );
  }

  // ── Load more button ───────────────────────────────────────
  Widget _buildLoadMoreButton(ColorScheme cs, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cs.primary,
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => context.read<ProjectsCubit>().loadMore(),
                icon: const Icon(Icons.expand_more_rounded, size: 20),
                label: const Text('Load More Projects'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(
                      color: cs.primary.withValues(alpha: 0.3), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────
  void _showLogoutDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('logout')),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Project Card Widget
// ══════════════════════════════════════════════════════════════

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int index;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.index,
    required this.onTap,
  });

  // Color palette for project cards — cycles through these with BeemView brand harmony
  static const List<_CardStyle> _styles = [
    _CardStyle(Color(0xFF0C5A75), Color(0xFF1E96BE), Icons.business_rounded), // BeemView Teal/Cyan
    _CardStyle(Color(0xFFE68A19), Color(0xFFFAAA3C), Icons.apartment_rounded), // BeemView Amber/Orange
    _CardStyle(Color(0xFF00796B), Color(0xFF52B79A), Icons.engineering_rounded), // Mint Green
    _CardStyle(Color(0xFF0277BD), Color(0xFF29B6F6), Icons.architecture_rounded), // Sky Blue
    _CardStyle(Color(0xFF5E35B1), Color(0xFF7E57C2), Icons.construction_rounded), // Deep Violet
    _CardStyle(Color(0xFF2E7D32), Color(0xFF4CAF50), Icons.landscape_rounded), // Emerald
  ];

  @override
  Widget build(BuildContext context) {
    final style = _styles[index % _styles.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [style.primary, style.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: style.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),

                  // Project name + id
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project #${project.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Styling for a project card.
class _CardStyle {
  final Color primary;
  final Color secondary;
  final IconData icon;
  const _CardStyle(this.primary, this.secondary, this.icon);
}
