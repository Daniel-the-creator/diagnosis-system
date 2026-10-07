import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/patient_model.dart';
import '../../core/utils/app_utils.dart';

/// Compact patient card for search results.
class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  final PatientModel patient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  AppUtils.getInitials(patient.fullName),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName,
                      style: AppTextStyles.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(patient.hospitalNumber,
                              style: AppTextStyles.hospitalNumber),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(patient.phone,
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Full patient search bar with results list.
class PatientSearchWidget extends StatefulWidget {
  const PatientSearchWidget({
    super.key,
    required this.onSearch,
    required this.results,
    required this.isSearching,
    required this.onSelect,
    this.hintText = 'Search by name, phone or hospital number...',
  });

  final Future<void> Function(String) onSearch;
  final List<PatientModel> results;
  final bool isSearching;
  final void Function(PatientModel) onSelect;
  final String hintText;

  @override
  State<PatientSearchWidget> createState() => _PatientSearchWidgetState();
}

class _PatientSearchWidgetState extends State<PatientSearchWidget> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _ctrl,
          onChanged: widget.onSearch,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ctrl.clear();
                      widget.onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        // Results
        if (widget.results.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...widget.results.map(
            (p) => PatientCard(
              patient: p,
              onTap: () => widget.onSelect(p),
            ),
          ),
        ],
      ],
    );
  }
}
