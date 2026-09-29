import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/queue_item_model.dart';
import '../../core/utils/app_utils.dart';

class QueueStatusChip extends StatelessWidget {
  const QueueStatusChip({super.key, required this.status});
  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _attrs();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.chipText.copyWith(color: color),
      ),
    );
  }

  (Color, Color, String) _attrs() {
    switch (status) {
      case QueueStatus.waiting:
        return (
          AppColors.queueWaiting,
          AppColors.warningLight,
          'Waiting'
        );
      case QueueStatus.called:
        return (AppColors.queueCalled, AppColors.infoLight, 'Called');
      case QueueStatus.inProgress:
        return (
          AppColors.queueInProgress,
          AppColors.successLight,
          'In Progress'
        );
      case QueueStatus.completed:
        return (
          AppColors.queueCompleted,
          AppColors.surfaceVariant,
          'Completed'
        );
      case QueueStatus.skipped:
        return (
          AppColors.queueSkipped,
          const Color(0xFFFFF3E0),
          'Skipped'
        );
      case QueueStatus.cancelled:
        return (
          AppColors.queueCancelled,
          AppColors.surfaceVariant,
          'Cancelled'
        );
      case QueueStatus.noShow:
        return (
          AppColors.queueNoShow,
          AppColors.errorLight,
          'No Show'
        );
      case QueueStatus.transferred:
        return (
          AppColors.queueTransferred,
          const Color(0xFFF3E5F5),
          'Transferred'
        );
    }
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.isEmergency});
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isEmergency ? AppColors.emergencyLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmergency
              ? AppColors.emergency.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmergency ? Icons.emergency : Icons.person,
            size: 12,
            color: isEmergency ? AppColors.emergency : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isEmergency ? 'Emergency' : 'Regular',
            style: AppTextStyles.chipText.copyWith(
              color:
                  isEmergency ? AppColors.emergency : AppColors.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class QueueItemCard extends StatelessWidget {
  const QueueItemCard({
    super.key,
    required this.item,
    this.patientName = 'Patient',
    this.onCall,
    this.onStart,
    this.onComplete,
    this.onSkip,
    this.onNoShow,
    this.onRecall,
    this.isExpanded = false,
  });

  final QueueItemModel item;
  final String patientName;
  final VoidCallback? onCall;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onNoShow;
  final VoidCallback? onRecall;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isEmergency = item.isEmergency;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency
              ? AppColors.emergency.withValues(alpha: 0.4)
              : AppColors.border,
          width: isEmergency ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Queue number badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isEmergency
                        ? AppColors.emergencyGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.queueNumber.split('-').first,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        item.queueNumber.split('-').last,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: AppTextStyles.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PriorityChip(isEmergency: isEmergency),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          QueueStatusChip(status: item.status),
                          const SizedBox(width: 8),
                          Text(
                            AppUtils.waitingTime(item.createdAt),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Action buttons
            if (item.status.isActive) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _ActionRow(
                status: item.status,
                onCall: onCall,
                onStart: onStart,
                onComplete: onComplete,
                onSkip: onSkip,
                onNoShow: onNoShow,
                onRecall: onRecall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.status,
    this.onCall,
    this.onStart,
    this.onComplete,
    this.onSkip,
    this.onNoShow,
    this.onRecall,
  });
  final QueueStatus status;
  final VoidCallback? onCall;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onNoShow;
  final VoidCallback? onRecall;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (status == QueueStatus.waiting) ...[
            if (onStart != null)
              _ActionBtn(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success,
                  onTap: onStart!),
            if (onCall != null)
              _ActionBtn(
                  label: 'Call',
                  icon: Icons.call,
                  color: AppColors.primary,
                  onTap: onCall!),
            if (onSkip != null)
              _ActionBtn(
                  label: 'Skip',
                  icon: Icons.skip_next,
                  color: AppColors.warning,
                  onTap: onSkip!),
          ],
          if (status == QueueStatus.called) ...[
            if (onStart != null)
              _ActionBtn(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success,
                  onTap: onStart!),
            if (onRecall != null)
              _ActionBtn(
                  label: 'Recall',
                  icon: Icons.replay,
                  color: AppColors.info,
                  onTap: onRecall!),
            if (onNoShow != null)
              _ActionBtn(
                  label: 'No Show',
                  icon: Icons.person_off,
                  color: AppColors.error,
                  onTap: onNoShow!),
          ],
          if (status == QueueStatus.inProgress && onComplete != null)
            _ActionBtn(
                label: 'Complete',
                icon: Icons.check_circle,
                color: AppColors.success,
                onTap: onComplete!),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTextStyles.labelMedium.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
