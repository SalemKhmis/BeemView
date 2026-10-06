import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/create_project/create_project_cubit.dart';
import '../blocs/create_project/create_project_state.dart';
import '../config/app_theme.dart';
import '../data/repositories/project_repository.dart';
import '../l10n/app_localizations.dart';

/// Screen for creating a new project.
///
/// Features:
/// - Name, description, status, start/end date inputs
/// - Date pickers with calendar UI
/// - Status dropdown with color-coded options
/// - Form validation
/// - Loading state during submission
/// - Success/error feedback via SnackBar
class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'planning';
  DateTime? _startDate;
  DateTime? _endDate;

  // Fixed organizational unit ID (as per API contract)
  static const int _organizationalUnitId = 71;

  static const List<_StatusOption> _statusOptions = [
    _StatusOption('planning', 'Planning', Icons.lightbulb_outline_rounded),
    _StatusOption('active', 'Active', Icons.play_circle_outline_rounded),
    _StatusOption('on_hold', 'On Hold', Icons.pause_circle_outline_rounded),
    _StatusOption('completed', 'Completed', Icons.check_circle_outline_rounded),
    _StatusOption('canceled', 'Canceled', Icons.cancel_outlined),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
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
          // Clear end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('dates_required')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    context.read<CreateProjectCubit>().createProject(
          name: _nameController.text.trim(),
          organizationalUnitId: _organizationalUnitId,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          status: _selectedStatus,
          startDate: dateFormat.format(_startDate!),
          endDate: dateFormat.format(_endDate!),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => CreateProjectCubit(
        projectRepository: RepositoryProvider.of<ProjectRepository>(context),
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
                  child: Icon(Icons.close_rounded,
                      size: 18, color: cs.primary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                context.tr('create_project_title'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: cs.onSurface,
                ),
              ),
            ),
            body: BlocListener<CreateProjectCubit, CreateProjectState>(
              listener: (context, state) {
                if (state is CreateProjectSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(context.tr('project_created')),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pop(context, true); // true = refresh list
                } else if (state is CreateProjectError) {
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
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                                AppTheme.secondaryColor.withValues(alpha: 0.10),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.create_new_folder_rounded,
                            size: 34,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Project Name ──
                      _buildLabel(context.tr('project_name'), isRequired: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: context.tr('project_name_hint'),
                          prefixIcon: Icon(Icons.folder_rounded,
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

                      // ── Status ──
                      _buildLabel(context.tr('status'), isRequired: true),
                      const SizedBox(height: 8),
                      _buildStatusSelector(cs),
                      const SizedBox(height: 20),

                      // ── Dates Row ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context.tr('start_date'), isRequired: true),
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
                                _buildLabel(context.tr('end_date'), isRequired: true),
                                const SizedBox(height: 8),
                                _buildDateButton(
                                    cs, _endDate, context.tr('select_end_date'), false),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // ── Submit Button ──
                      BlocBuilder<CreateProjectCubit, CreateProjectState>(
                        builder: (context, state) {
                          final isLoading = state is CreateProjectSubmitting;
                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed:
                                  isLoading ? null : () => _submit(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppTheme.primaryColor.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                                shadowColor:
                                    AppTheme.primaryColor.withValues(alpha: 0.4),
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
                                          context.tr('create_project_btn'),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildStatusSelector(ColorScheme cs) {
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        items: _statusOptions.map((opt) {
          return DropdownMenuItem(
            value: opt.value,
            child: Row(
              children: [
                Icon(opt.icon,
                    size: 18, color: _statusColor(opt.value)),
                const SizedBox(width: 10),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
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
              size: 16,
              color: date != null
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatted ?? hint,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                  color: date != null
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'planning' => const Color(0xFF9E9E9E),
      'active' => AppTheme.primaryColor,
      'on_hold' => AppTheme.secondaryColor,
      'completed' => const Color(0xFF4CAF50),
      'canceled' => const Color(0xFF607D8B),
      _ => const Color(0xFF9E9E9E),
    };
  }
}

class _StatusOption {
  final String value;
  final String label;
  final IconData icon;

  const _StatusOption(this.value, this.label, this.icon);
}
