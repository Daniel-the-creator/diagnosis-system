import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_utils.dart';

class SidebarItem {
  const SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });
  final IconData icon;
  final String label;
  final String route;
  final int? badge;
}

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    super.key,
    required this.items,
    required this.activeRoute,
  });

  final List<SidebarItem> items;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
      ),
      child: Column(
        children: [
          // ── Logo / App name ─────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MediFlow',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                      Text('HMS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.sidebarText,
                            letterSpacing: 2,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── User info ───────────────────────────────────────────
          Obx(() {
            final user = auth.user;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sidebarHover,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      AppUtils.getInitials(user?.fullName ?? '?'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppUtils.getRoleLabel(user?.role ?? ''),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.sidebarText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Navigation items ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                children: items
                    .map((item) => _SidebarItemTile(
                          item: item,
                          isActive: activeRoute == item.route,
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── Sign out ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SidebarItemTile(
              item: const SidebarItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                route: '__logout__',
              ),
              isActive: false,
              onTap: () => _confirmSignOut(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.find<AuthController>().signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemTile extends StatefulWidget {
  const _SidebarItemTile({
    required this.item,
    required this.isActive,
    this.onTap,
  });
  final SidebarItem item;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap ??
            () {
              if (!widget.isActive) {
                Get.offNamed(widget.item.route);
              }
            },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.sidebarActive
                : _hovering
                    ? AppColors.sidebarHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.isActive
                    ? Colors.white
                    : AppColors.sidebarText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: widget.isActive
                      ? AppTextStyles.sidebarItemActive
                      : AppTextStyles.sidebarItem,
                ),
              ),
              if (widget.item.badge != null && widget.item.badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.item.badge}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
