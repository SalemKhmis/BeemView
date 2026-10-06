import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/profile/profile_cubit.dart';
import '../blocs/profile/profile_state.dart';
import '../blocs/theme/theme_cubit.dart';
import '../blocs/locale/locale_cubit.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/theme_toggle_button.dart';

/// Screen: User Profile with Modern BeemView Design
///
/// Fetches profile from `GET /api/users/me/profile` via [ProfileCubit]
/// Features:
/// - Real-time pull-to-refresh
/// - Personal details & Workspace information
/// - Interactive Theme & Language toggles
/// - Session security & Logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger fresh profile fetch on screen mount
    context.read<ProfileCubit>().loadProfile();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label ${context.tr('copied_to_clipboard')}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileLoading
                  ? state.cachedUser
                  : state is ProfileError
                      ? state.cachedUser
                      : null;

          if (state is ProfileLoading && user == null) {
            return _buildLoadingState(cs);
          }

          if (state is ProfileError && user == null) {
            return _buildErrorState(cs, state.message);
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<ProfileCubit>().loadProfile(isRefresh: true),
            color: cs.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverAppBar(cs, user),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null) ...[
                          _buildPersonalInfoCard(cs, user),
                          const SizedBox(height: 16),
                          _buildWorkspaceCard(cs, user),
                          const SizedBox(height: 16),
                        ],
                        _buildPreferencesCard(cs),
                        const SizedBox(height: 16),
                        _buildSessionCard(cs),
                        const SizedBox(height: 24),
                        _buildLogoutButton(cs),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 1. Hero Sliver App Bar ────────────────────────────────────
  Widget _buildSliverAppBar(ColorScheme cs, User? user) {
    final displayName = user?.fullName ?? 'User Profile';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.darkTeal,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A4B60), // Dark Teal
                Color(0xFF167B9E), // Mid Teal
                Color(0xFF1E96BE), // BeemView Cyan
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Glowing Avatar Frame
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAAA3C), Color(0xFF1E96BE), Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFF0E5A73),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Subtitle / Email Pill
                if (user?.email != null && user!.email!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      user.email!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const ThemeToggleButton(isCompact: true),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const LanguageToggleButton(isCompact: true),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── 2. Personal Information Card ──────────────────────────────
  Widget _buildPersonalInfoCard(ColorScheme cs, User user) {
    return _buildSectionCard(
      cs: cs,
      title: context.tr('personal_info'),
      icon: Icons.person_outline_rounded,
      iconColor: AppTheme.primaryColor,
      children: [
        _buildInfoTile(
          cs: cs,
          icon: Icons.badge_outlined,
          label: context.tr('full_name'),
          value: user.fullName,
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          const Divider(height: 1),
          _buildInfoTile(
            cs: cs,
            icon: Icons.email_outlined,
            label: context.tr('email_address'),
            value: user.email!,
            onTap: () => _copyToClipboard(user.email!, context.tr('email_address')),
            trailing: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryColor),
          ),
        ],
        if (user.phone != null && user.phone!.isNotEmpty) ...[
          const Divider(height: 1),
          _buildInfoTile(
            cs: cs,
            icon: Icons.phone_outlined,
            label: context.tr('phone_number'),
            value: user.phone!,
          ),
        ],
        const Divider(height: 1),
        _buildInfoTile(
          cs: cs,
          icon: Icons.tag_rounded,
          label: context.tr('user_id'),
          value: '#${user.id}',
          onTap: () => _copyToClipboard(user.id.toString(), context.tr('user_id')),
          trailing: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  // ── 3. Workspace & Role Card ──────────────────────────────────
  Widget _buildWorkspaceCard(ColorScheme cs, User user) {
    return _buildSectionCard(
      cs: cs,
      title: context.tr('workspace_info'),
      icon: Icons.business_center_outlined,
      iconColor: const Color(0xFFFAAA3C),
      children: [
        _buildInfoTile(
          cs: cs,
          icon: Icons.domain_rounded,
          label: context.tr('tenant'),
          value: ApiConfig.subdomain,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Workspace',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        if (user.role != null && user.role!.isNotEmpty) ...[
          const Divider(height: 1),
          _buildInfoTile(
            cs: cs,
            icon: Icons.shield_outlined,
            label: context.tr('role'),
            value: user.role!,
          ),
        ],
        if (user.jobTitle != null && user.jobTitle!.isNotEmpty) ...[
          const Divider(height: 1),
          _buildInfoTile(
            cs: cs,
            icon: Icons.work_outline_rounded,
            label: context.tr('job_title'),
            value: user.jobTitle!,
          ),
        ],
        if (user.department != null && user.department!.isNotEmpty) ...[
          const Divider(height: 1),
          _buildInfoTile(
            cs: cs,
            icon: Icons.apartment_rounded,
            label: context.tr('department'),
            value: user.department!,
          ),
        ],
        const Divider(height: 1),
        _buildInfoTile(
          cs: cs,
          icon: Icons.verified_user_rounded,
          label: context.tr('account_status'),
          value: context.tr('active_status'),
          valueColor: const Color(0xFF10B981),
          trailing: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Preferences & Settings Card ────────────────────────────
  Widget _buildPreferencesCard(ColorScheme cs) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark;
    final locale = context.watch<LocaleCubit>().state;
    final isArabic = locale.languageCode == 'ar';

    return _buildSectionCard(
      cs: cs,
      title: context.tr('preferences_settings'),
      icon: Icons.tune_rounded,
      iconColor: const Color(0xFF9C27B0),
      children: [
        // Theme Switch
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFFFAAA3C) : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 20,
              color: isDark ? const Color(0xFFFAAA3C) : AppTheme.primaryColor,
            ),
          ),
          title: Text(
            context.tr('theme'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isDark ? context.tr('dark_mode') : context.tr('light_mode'),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: Switch.adaptive(
            value: isDark,
            activeTrackColor: const Color(0xFFFAAA3C),
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
          ),
        ),
        const Divider(height: 1),
        // Language Switch
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          title: Text(
            context.tr('language'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isArabic ? context.tr('arabic') : context.tr('english'),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: const LanguageToggleButton(isCompact: true),
        ),
      ],
    );
  }

  // ── 5. Session & Security Card ────────────────────────────────
  Widget _buildSessionCard(ColorScheme cs) {
    return _buildSectionCard(
      cs: cs,
      title: context.tr('session_security'),
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFF00897B),
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.security_rounded,
              size: 20,
              color: Color(0xFF10B981),
            ),
          ),
          title: Text(
            context.tr('authenticated_session'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            context.tr('secure_storage_active'),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
        ),
      ],
    );
  }

  // ── 6. Logout Button ──────────────────────────────────────────
  Widget _buildLogoutButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(cs),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.error,
          side: BorderSide(color: cs.error.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          context.tr('logout'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Section Card Template ─────────────────────────────────────
  Widget _buildSectionCard({
    required ColorScheme cs,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  // ── Info Tile ─────────────────────────────────────────────────
  Widget _buildInfoTile({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────
  Widget _buildLoadingState(ColorScheme cs) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              context.tr('user_profile'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────
  Widget _buildErrorState(ColorScheme cs, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.read<ProfileCubit>().loadProfile(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr('try_again')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
