import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pharmacy_controller.dart';
import '../../models/medication_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';

class PharmacyDashboardView extends StatelessWidget {
  const PharmacyDashboardView({super.key});

  static const List<SidebarItem> _sidebar = [
    SidebarItem(
        icon: Icons.medication,
        label: 'Pharmacy & Inventory',
        route: AppRoutes.pharmacyDashboard),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'Pharmacy & Medication Dispensary',
      sidebarItems: isAdmin ? AppScaffold.adminSidebarItems : _sidebar,
      activeRoute: AppRoutes.pharmacyDashboard,
      child: const _PharmacyBody(),
    );
  }
}

class _PharmacyBody extends StatefulWidget {
  const _PharmacyBody();

  @override
  State<_PharmacyBody> createState() => _PharmacyBodyState();
}

class _PharmacyBodyState extends State<_PharmacyBody> {
  late final PharmacyController _ctrl;
  final _auth = Get.find<AuthController>();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PharmacyController>()) {
      _ctrl = Get.find<PharmacyController>();
    } else {
      _ctrl = Get.put(PharmacyController(Get.find(), Get.find(),
          notificationRepo: Get.find()));
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              tabs: [
                Tab(
                    icon: Icon(Icons.receipt_outlined),
                    text: 'Prescriptions Queue'),
                Tab(
                    icon: Icon(Icons.inventory_2_outlined),
                    text: 'Medication Inventory & Stock'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPrescriptionsQueueView(),
                _buildInventoryView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsQueueView() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 900;
    final listWidth =
        screenWidth > 1300 ? 420.0 : (screenWidth > 1100 ? 360.0 : 310.0);
    return Obx(() {
      final hasSelected = _ctrl.selectedPrescription.value != null;
      if (isWide) {
        return Row(
          children: [
            SizedBox(width: listWidth, child: _buildRxList()),
            const VerticalDivider(width: 1),
            Expanded(child: _buildDispensePanel()),
          ],
        );
      }
      if (hasSelected) {
        return Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _ctrl.selectedPrescription.value = null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to Prescriptions'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildDispensePanel()),
          ],
        );
      }
      return _buildRxList();
    });
  }

  Widget _buildRxList() {
    return Obx(() {
      final rxs = _ctrl.displayedPrescriptions;
      final currentFilter = _ctrl.filterStatus.value;

      return Column(
        children: [
          // ── Status Filter ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Filter: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'PENDING', label: Text('Pending Queue')),
                      ButtonSegment(
                          value: 'DISPENSED', label: Text('Dispensed History')),
                      ButtonSegment(
                          value: 'ALL', label: Text('All Prescriptions')),
                    ],
                    selected: {currentFilter},
                    onSelectionChanged: (set) => _ctrl.setFilter(set.first),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ── List or Empty State ─────────────────────────────
          Expanded(
            child: rxs.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text('No $currentFilter prescriptions found.'),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rxs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final rx = rxs[idx];
                      final isSelected =
                          _ctrl.selectedPrescription.value?.prescriptionId ==
                              rx.prescriptionId;
                      final isDispensed = rx.status == 'DISPENSED';

                      return Card(
                        elevation: isSelected ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? const BorderSide(
                                  color: AppColors.primary, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rx.patientName.isNotEmpty
                                      ? rx.patientName
                                      : 'Patient',
                                  style: AppTextStyles.h4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDispensed
                                          ? AppColors.success
                                          : AppColors.primary)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rx.status,
                                  style: TextStyle(
                                    color: isDispensed
                                        ? AppColors.success
                                        : AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${rx.medicationName} (${rx.dosage})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  '${rx.frequency} • Total: ${rx.quantity} (Remaining: ${rx.remaining})',
                                  style: AppTextStyles.bodySmall),
                              Text('Prescribed by: Dr. ${rx.doctorName}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          trailing: AppButton(
                            height: 36,
                            text: isDispensed
                                ? 'View'
                                : (isSelected ? 'Active' : 'Dispense'),
                            onPressed: () {
                              _ctrl.selectPrescription(rx);
                              _qtyCtrl.text = rx.remaining.toString();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildDispensePanel() {
    return Obx(() {
      final rx = _ctrl.selectedPrescription.value;
      final matchedMed = _ctrl.matchedMedication.value;

      if (rx == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medication_liquid_outlined,
                  size: 54, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                  'Select a prescription to verify stock and dispense medication.'),
            ],
          ),
        );
      }

      final hasStock = matchedMed != null &&
          matchedMed.quantity >= _ctrl.dispenseQuantity.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rx.patientName, style: AppTextStyles.h3),
                            Text('Doctor: Dr. ${rx.doctorName}',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _ctrl.clearSelection),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Medication Order', style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    Text('${rx.medicationName} — ${rx.dosage}',
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                        'Dosage Directions: ${rx.frequency} for ${rx.duration}',
                        style: AppTextStyles.bodyMedium),
                    if (rx.instructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Instructions: ${rx.instructions}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                        'Required Quantity: ${rx.quantity} | Dispensed: ${rx.dispensedQuantity} | Outstanding: ${rx.remaining}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Inventory Stock Verification', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: hasStock
                        ? AppColors.success.withOpacity(0.4)
                        : AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                      hasStock
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: hasStock ? AppColors.success : AppColors.error,
                      size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchedMed != null
                              ? matchedMed.drugName
                              : 'No matching inventory drug found!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          matchedMed != null
                              ? 'In Stock: ${matchedMed.quantity} units (Batch: ${matchedMed.batchNumber})'
                              : 'Please check inventory stock name',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _qtyCtrl,
                    label: 'Quantity to Dispense Now',
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _ctrl.dispenseQuantity.value = int.tryParse(v) ?? 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (_ctrl.errorMessage.value.isEmpty)
                return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_ctrl.errorMessage.value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              );
            }),
            Obx(() => AppButton(
                  text: 'Dispense & Deduct from Stock',
                  onPressed: hasStock
                      ? () => _ctrl.dispense(
                            staffId: _auth.user?.uid ?? '',
                            staffName: _auth.userName,
                          )
                      : null,
                  isLoading: _ctrl.isLoading.value,
                  isFullWidth: true,
                  icon: Icons.check_circle_rounded,
                )),
          ],
        ),
      );
    });
  }

  Widget _buildInventoryView() {
    return Obx(() {
      final meds = _ctrl.inventory;
      final lowStock = _ctrl.lowStockAlerts;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lowStock.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Low Stock / Expiry Alert (${lowStock.length} drugs)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning)),
                          Text(
                              'The following medications require restocking or are approaching expiration: ${lowStock.map((m) => m.drugName).take(3).join(', ')}',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Pharmacy Drug Inventory (${meds.length} items)',
                    style: AppTextStyles.h3),
                AppButton(
                  text: 'Add Medication',
                  icon: Icons.add,
                  onPressed: _showAddMedicationDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meds.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) {
                  final m = meds[idx];
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(m.drugName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text('${m.quantity} in stock',
                            style: TextStyle(
                                color: m.isLowStock
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: Text(
                        'Generic: ${m.genericName} • Category: ${m.category} • Batch: ${m.batchNumber} • Price: \$${m.unitPrice.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart,
                          color: AppColors.primary),
                      tooltip: 'Restock (+50)',
                      onPressed: () =>
                          _ctrl.restockMedication(m.medicationId, 50),
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

  void _showAddMedicationDialog() {
    final nameCtrl = TextEditingController();
    final genCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Analgesics');
    final batchCtrl = TextEditingController(
        text:
            'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final qtyCtrl = TextEditingController(text: '100');
    final priceCtrl = TextEditingController(text: '15.0');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Medication to Inventory',
                    style: AppTextStyles.h3),
                const SizedBox(height: 16),
                AppTextField(
                    controller: nameCtrl,
                    label: 'Drug Brand Name',
                    hint: 'e.g. Paracetamol 500mg'),
                const SizedBox(height: 12),
                AppTextField(
                    controller: genCtrl,
                    label: 'Generic Name',
                    hint: 'e.g. Acetaminophen'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            controller: catCtrl, label: 'Category')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: AppTextField(
                            controller: batchCtrl, label: 'Batch No')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            controller: qtyCtrl,
                            label: 'Initial Qty',
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: AppTextField(
                            controller: priceCtrl, label: 'Unit Price (\$)')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Save Drug',
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final id =
                            'med_${DateTime.now().millisecondsSinceEpoch}';
                        _ctrl.saveMedication(
                          MedicationModel(
                            medicationId: id,
                            drugName: nameCtrl.text.trim(),
                            genericName: genCtrl.text.trim(),
                            category: catCtrl.text.trim(),
                            batchNumber: batchCtrl.text.trim(),
                            quantity: int.tryParse(qtyCtrl.text.trim()) ?? 0,
                            unitPrice:
                                double.tryParse(priceCtrl.text.trim()) ?? 10.0,
                            expiryDate:
                                DateTime.now().add(const Duration(days: 365)),
                            minimumStockLevel: 20,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        Get.back();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
