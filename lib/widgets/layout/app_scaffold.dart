import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../repositories/notification_repository.dart';
import '../../views/shared/notification_center_view.dart';
import '../common/network_status_widget.dart';
import 'sidebar_widget.dart';

/// Main scaffold that wraps all dashboard views.
/// Desktop (width >= 960): permanent sidebar + content.
/// Mobile/Tablet (width < 960): drawer + appbar for full width clinical workspace.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.sidebarItems,
    required this.activeRoute,
    this.actions,
    this.floatingActionButton,
    this.topBarTrailing,
  });

  final String title;
  final Widget child;
  final List<SidebarItem> sidebarItems;
  final String activeRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? topBarTrailing;

  /// Comprehensive Super Admin navigation list covering all hospital operations.
  static const List<SidebarItem> adminSidebarItems = [
    SidebarItem(
      icon: Icons.dashboard_rounded,
      label: 'Admin Dashboard',
      route: AppRoutes.adminDashboard,
    ),
    SidebarItem(
      icon: Icons.meeting_room_rounded,
      label: 'Gate Security',
      route: AppRoutes.gateDashboard,
    ),
    SidebarItem(
      icon: Icons.how_to_reg_rounded,
      label: 'Registration Desk',
      route: AppRoutes.registrationDashboard,
    ),
    SidebarItem(
      icon: Icons.medical_services_rounded,
      label: 'Doctor Queue',
      route: AppRoutes.doctorDashboard,
    ),
    SidebarItem(
      icon: Icons.biotech_rounded,
      label: 'Diagnostics & Lab',
      route: AppRoutes.diagnosticDashboard,
    ),
    SidebarItem(
      icon: Icons.receipt_long_rounded,
      label: 'Billing & Cashier',
      route: AppRoutes.accountDashboard,
    ),
    SidebarItem(
      icon: Icons.medication_rounded,
      label: 'Pharmacy & Stock',
      route: AppRoutes.pharmacyDashboard,
    ),
    SidebarItem(
      icon: Icons.hotel_rounded,
      label: 'Wards & Admissions',
      route: AppRoutes.admissionDashboard,
    ),
  ];

  List<SidebarItem> _resolveSidebarItems() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isAdmin) {
        return adminSidebarItems;
      }
    }
    return sidebarItems;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveItems = _resolveSidebarItems();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    if (!isDesktop) {
      return _MobileScaffold(
        title: title,
        sidebarItems: effectiveItems,
        activeRoute: activeRoute,
        actions: actions,
        floatingActionButton: floatingActionButton,
        child: child,
      );
    }

    return _DesktopScaffold(
      title: title,
      sidebarItems: effectiveItems,
      activeRoute: activeRoute,
      topBarTrailing: topBarTrailing,
      floatingActionButton: floatingActionButton,
      child: child,
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({
    required this.title,
    required this.child,
    required this.sidebarItems,
    required this.activeRoute,
    this.topBarTrailing,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<SidebarItem> sidebarItems;
  final String activeRoute;
  final Widget? topBarTrailing;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SidebarWidget(items: sidebarItems, activeRoute: activeRoute),
          Expanded(
            child: Column(
              children: [
                // Network resilience banner
                const NetworkStatusBanner(),
                // Top bar
                _TopBar(
                  title: title,
                  activeRoute: activeRoute,
                  trailing: topBarTrailing,
                ),
                // Content
                Expanded(
                  child: floatingActionButton == null
                      ? child
                      : Stack(
                          children: [
                            child,
                            Positioned(
                              bottom: 24,
                              right: 24,
                              child: floatingActionButton!,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.activeRoute,
    this.trailing,
  });

  final String title;
  final String activeRoute;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isAdmin = auth?.isAdmin ?? false;
    final showReturnToAdmin = isAdmin && activeRoute != AppRoutes.adminDashboard;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
          ],
          if (showReturnToAdmin) ...[
            TextButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.adminDashboard),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: 8),
          const _NotificationBellButton(),
          const SizedBox(width: 12),
          // Clock
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (ctx, _) {
              final now = DateTime.now();
              final time =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              return Text(
                time,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({
    required this.title,
    required this.child,
    required this.sidebarItems,
    required this.activeRoute,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<SidebarItem> sidebarItems;
  final String activeRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isAdmin = auth?.isAdmin ?? false;
    final showReturnToAdmin = isAdmin && activeRoute != AppRoutes.adminDashboard;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          const _NotificationBellButton(),
          if (showReturnToAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin Dashboard',
              onPressed: () => Get.offAllNamed(AppRoutes.adminDashboard),
            ),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: Drawer(
        child: SidebarWidget(
          items: sidebarItems,
          activeRoute: activeRoute,
        ),
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>() || !Get.isRegistered<NotificationRepository>()) {
      return const SizedBox.shrink();
    }
    final auth = Get.find<AuthController>();
    final notifRepo = Get.find<NotificationRepository>();
    final uid = auth.user?.uid;
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: notifRepo.streamUnreadCount(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          tooltip: 'Notification Center',
          onPressed: () => NotificationCenterView.show(context),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
        );
      },
    );
  }
}
