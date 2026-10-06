import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/theme/theme_cubit.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Reusable branded Theme Switcher button (Light ↔ Dark Mode).
class ThemeToggleButton extends StatelessWidget {
  final bool isCompact;

  const ThemeToggleButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    final tooltipText = isDark
        ? AppLocalizations.of(context).translate('light_mode')
        : AppLocalizations.of(context).translate('dark_mode');

    return Tooltip(
      message: tooltipText,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.8)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFAAA3C).withValues(alpha: 0.4)
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: const Color(0xFFFAAA3C).withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      RotationTransition(turns: animation, child: child),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    size: 15,
                    color: isDark
                        ? const Color(0xFFFAAA3C)
                        : AppTheme.primaryColor,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  Text(
                    isDark ? 'Light' : 'Dark',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFFAAA3C)
                          : AppTheme.primaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
