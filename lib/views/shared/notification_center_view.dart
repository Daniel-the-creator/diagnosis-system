import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../../controllers/auth_controller.dart';

/// Modal/BottomSheet notification center providing category filtering, read status management,
/// and archival.
class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key});

  static Future<void> show(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isPhone = screen.width < 600;
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
            horizontal: isPhone ? 12 : 24, vertical: isPhone ? 16 : 24),
        child: SizedBox(
          width: isPhone ? screen.width : 580,
          height: isPhone ? screen.height * 0.85 : 680,
          child: const NotificationCenterView(),
        ),
      ),
    );
  }

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  final NotificationRepository _notifRepo = Get.find<NotificationRepository>();
  final AuthController _authCtrl = Get.find<AuthController>();

  String _selectedCategory = 'ALL';
  final List<String> _categories = [
    'ALL',
    'QUEUE',
    'MEDICAL',
    'PAYMENT',
    'APPOINTMENT',
    'PHARMACY',
    'ADMISSION',
    'SYSTEM',
  ];

  @override
  Widget build(BuildContext context) {
    final uid = _authCtrl.user?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _buildHeader(uid),
          const Divider(height: 1),

          // ── Category Filter Bar ─────────────────────────────────
          _buildCategoryChips(),
          const Divider(height: 1),

          // ── Notification Stream List ────────────────────────────
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notifRepo.streamUserNotifications(
                uid,
                category: _selectedCategory,
                includeArchived: false,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifs = snapshot.data ?? [];
                if (notifs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final item = notifs[index];
                    return _buildNotificationTile(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String uid) {
    final isPhone = MediaQuery.of(context).size.width < 500;
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isPhone ? 14 : 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPhone ? 'Notifications' : 'Notification Center',
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPhone)
                IconButton(
                  tooltip: 'Mark all read',
                  icon: const Icon(Icons.done_all_rounded,
                      size: 20, color: AppColors.primary),
                  onPressed: () async {
                    await _notifRepo.markAllAsRead(uid);
                  },
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    await _notifRepo.markAllAsRead(uid);
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Mark all read',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final cat = _categories[idx];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.background,
            onSelected: (val) {
              if (val) setState(() => _selectedCategory = cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel item) {
    final iconData = _getCategoryIcon(item.category);
    final iconColor = _getCategoryColor(item.category);
    final timeStr = DateFormat('MMM d, h:mm a').format(item.createdAt);

    return Container(
      color: item.read
          ? Colors.transparent
          : AppColors.primary.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(iconData, color: iconColor, size: 18),
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
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              item.read ? FontWeight.w600 : FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!item.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    Row(
                      children: [
                        if (!item.read)
                          InkWell(
                            onTap: () =>
                                _notifRepo.markAsRead(item.notificationId),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Text('Mark read',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        InkWell(
                          onTap: () => _notifRepo
                              .archiveNotification(item.notificationId),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text('Archive',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            _selectedCategory == 'ALL'
                ? 'No notifications found'
                : 'No $_selectedCategory notifications',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'You are completely caught up with all hospital alerts.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'QUEUE':
        return Icons.people_alt_rounded;
      case 'MEDICAL':
        return Icons.medical_services_rounded;
      case 'PAYMENT':
        return Icons.receipt_long_rounded;
      case 'APPOINTMENT':
        return Icons.calendar_today_rounded;
      case 'PHARMACY':
        return Icons.medication_rounded;
      case 'ADMISSION':
        return Icons.hotel_rounded;
      case 'SYSTEM':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'QUEUE':
        return AppColors.secondary;
      case 'MEDICAL':
        return AppColors.primary;
      case 'PAYMENT':
        return const Color(0xFF00897B);
      case 'APPOINTMENT':
        return const Color(0xFF3949AB);
      case 'PHARMACY':
        return const Color(0xFFE65100);
      case 'ADMISSION':
        return const Color(0xFF1565C0);
      case 'SYSTEM':
      default:
        return AppColors.textSecondary;
    }
  }
}
