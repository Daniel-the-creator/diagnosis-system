import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/digital_queue_display_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/route_constants.dart';

class DigitalQueueDisplayView extends StatefulWidget {
  const DigitalQueueDisplayView({super.key});

  @override
  State<DigitalQueueDisplayView> createState() => _DigitalQueueDisplayViewState();
}

class _DigitalQueueDisplayViewState extends State<DigitalQueueDisplayView> {
  late final DigitalQueueDisplayController _ctrl;
  late final Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<DigitalQueueDisplayController>()) {
      _ctrl = Get.find<DigitalQueueDisplayController>();
    } else {
      _ctrl = Get.put(DigitalQueueDisplayController(Get.find()));
    }
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  void _exitDisplay() {
    if (Navigator.of(context).canPop()) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.adminDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _exitDisplay,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark high-contrast cinema canvas
          body: SafeArea(
            child: Column(
              children: [
                _buildDisplayHeader(),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Row(
                      children: [
                        // Left 60%: NOW SERVING (Prominent & High Contrast)
                        Expanded(flex: 6, child: _buildNowServingPanel()),
                        const SizedBox(width: 28),
                        // Right 40%: UP NEXT
                        Expanded(flex: 4, child: _buildUpNextPanel()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Back to Dashboard / Exit Button
              Tooltip(
                message: 'Exit TV Display & Return to Dashboard (Esc)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _exitDisplay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Exit Display',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MediFlow HMS',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  Text(
                    'Patient Queue & Waiting Room Display',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          // Department filter chips
          Obx(() {
            return Row(
              children: [
                _buildDeptChip('ALL', 'All Units'),
                const SizedBox(width: 8),
                _buildDeptChip('GEN', 'Doctor OPD'),
                const SizedBox(width: 8),
                _buildDeptChip('LAB', 'Laboratory'),
                const SizedBox(width: 8),
                _buildDeptChip('XR', 'X-Ray'),
                const SizedBox(width: 8),
                _buildDeptChip('SCAN', 'Ultrasound'),
                const SizedBox(width: 8),
                _buildDeptChip('PHARM', 'Pharmacy'),
              ],
            );
          }),
          // Audio announcement toggle & Real-time Clock
          Row(
            children: [
              Obx(() {
                final isAudioOn = _ctrl.audioEnabled.value;
                return IconButton(
                  tooltip: isAudioOn
                      ? 'Mute Voice Announcements'
                      : 'Enable Voice Announcements',
                  onPressed: _ctrl.toggleAudio,
                  icon: Icon(
                    isAudioOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color:
                        isAudioOn ? const Color(0xFF38BDF8) : Colors.white38,
                    size: 26,
                  ),
                );
              }),
              const SizedBox(width: 16),
              StreamBuilder<DateTime>(
                stream: _clockStream,
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.jms().format(now),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                      Text(
                        DateFormat.yMMMMEEEEd().format(now),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptChip(String code, String label) {
    final isSelected = _ctrl.selectedDept.value == code;
    return InkWell(
      onTap: () => _ctrl.setDepartment(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNowServingPanel() {
    return Obx(() {
      final serving = _ctrl.currentlyServing.value;
      final isFlash = _ctrl.hasNewCall.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isFlash ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFlash ? const Color(0xFF60A5FA) : const Color(0xFF334155),
            width: isFlash ? 4 : 2,
          ),
          boxShadow: isFlash
              ? [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 30, spreadRadius: 4),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isFlash ? const Color(0xFF22C55E) : const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isFlash ? Icons.campaign_rounded : Icons.person_pin_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isFlash ? 'NOW CALLING' : 'NOW SERVING',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (serving == null) ...[
              const Icon(Icons.hourglass_empty_rounded, color: Colors.white38, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Waiting for Next Patient',
                style: TextStyle(color: Colors.white60, fontSize: 26, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  serving.displayQueueNumber,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                serving.departmentName.toUpperCase(),
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatRoomText(serving.assignedRoomNumber ?? serving.assignedRoomName ?? 'Consultation Room'),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formatRoomText(String rawRoom) {
    final trimmed = rawRoom.trim();
    if (trimmed.isEmpty) return 'Please proceed to Consultation Room';
    if (trimmed.toLowerCase().contains('room')) {
      return 'Please proceed to $trimmed';
    }
    return 'Please proceed to Room $trimmed';
  }

  Widget _buildUpNextPanel() {
    return Obx(() {
      final upcoming = _ctrl.upNextList;

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF334155), width: 2),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 10),
                const Text(
                  'UP NEXT',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const Spacer(),
                Text(
                  '${upcoming.length} in queue',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 16),
            if (upcoming.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No upcoming patients in line.', style: TextStyle(color: Colors.white38, fontSize: 16)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = upcoming[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${idx + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.displayQueueNumber,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.departmentCode,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}
