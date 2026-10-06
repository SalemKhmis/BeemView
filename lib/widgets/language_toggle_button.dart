import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/locale/locale_cubit.dart';
import '../config/app_theme.dart';

/// Reusable branded language switcher button (EN ↔ العربية).
class LanguageToggleButton extends StatelessWidget {
  final bool isCompact;

  const LanguageToggleButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    final isArabic = locale.languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<LocaleCubit>().toggleLocale(),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'العربية' : 'EN',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
