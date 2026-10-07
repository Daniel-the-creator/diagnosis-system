import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/billing_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';

class BillingDashboardView extends StatelessWidget {
  const BillingDashboardView({super.key});

  static const List<SidebarItem> _sidebar = [
    SidebarItem(
        icon: Icons.receipt_long,
        label: 'Billing & Cashier',
        route: AppRoutes.accountDashboard),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'Billing & Cashier Desk',
      sidebarItems: isAdmin ? AppScaffold.adminSidebarItems : _sidebar,
      activeRoute: AppRoutes.accountDashboard,
      child: const _BillingBody(),
    );
  }
}

class _BillingBody extends StatefulWidget {
  const _BillingBody();

  @override
  State<_BillingBody> createState() => _BillingBodyState();
}

class _BillingBodyState extends State<_BillingBody> {
  late final BillingController _ctrl;
  final _auth = Get.find<AuthController>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BillingController>()) {
      _ctrl = Get.find<BillingController>();
    } else {
      _ctrl = Get.put(BillingController(Get.find(), Get.find(),
          notificationRepo: Get.find()));
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 900;
    final listWidth =
        screenWidth > 1300 ? 420.0 : (screenWidth > 1100 ? 360.0 : 310.0);

    return isWide
        ? Row(
            children: [
              SizedBox(width: listWidth, child: _buildInvoiceList()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildPaymentPanel()),
            ],
          )
        : Obx(() {
            final hasSelected = _ctrl.selectedInvoice.value != null;
            if (hasSelected) {
              return Column(
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _ctrl.selectedInvoice.value = null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Back to Invoices'),
                        ),
                        const Spacer(),
                        Text(
                          'Payment Desk',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildPaymentPanel()),
                ],
              );
            }
            return _buildInvoiceList();
          });
  }

  Widget _buildInvoiceList() {
    return Obx(() {
      final invoices = _ctrl.displayedInvoices;
      final currentFilter = _ctrl.filterStatus.value;

      return Column(
        children: [
          // ── Financial Overview Banner ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Collected',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        '\$${_ctrl.totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Balance',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        '\$${_ctrl.totalPendingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                      ButtonSegment(value: 'PENDING', label: Text('Pending')),
                      ButtonSegment(
                          value: 'PAID', label: Text('Paid / Settled')),
                      ButtonSegment(value: 'ALL', label: Text('All Invoices')),
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
            child: invoices.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text('No $currentFilter invoices found.'),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final inv = invoices[idx];
                      final isSelected =
                          _ctrl.selectedInvoice.value?.invoiceId ==
                              inv.invoiceId;
                      final isPaid = inv.status == 'PAID';

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
                                  inv.patientName.isNotEmpty
                                      ? inv.patientName
                                      : 'Patient',
                                  style: AppTextStyles.h4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPaid
                                          ? AppColors.success
                                          : AppColors.primary)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid
                                      ? 'PAID'
                                      : '\$${inv.balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isPaid
                                        ? AppColors.success
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  'Invoice #${inv.invoiceId.length > 8 ? inv.invoiceId.substring(0, 8).toUpperCase() : inv.invoiceId} • ${inv.items.length} items',
                                  style: AppTextStyles.caption),
                              Text(
                                  'Total: \$${inv.total.toStringAsFixed(2)} • Paid: \$${inv.amountPaid.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                          trailing: AppButton(
                            height: 36,
                            text: isPaid
                                ? 'View'
                                : (isSelected ? 'Active' : 'Pay'),
                            onPressed: () {
                              _ctrl.selectInvoice(inv);
                              _amountCtrl.text = inv.balance.toStringAsFixed(2);
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

  Widget _buildPaymentPanel() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    return Obx(() {
      final inv = _ctrl.selectedInvoice.value;

      if (inv == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.point_of_sale_outlined,
                  size: 54, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                  'Select an invoice to process cashier payment and generate receipt.'),
            ],
          ),
        );
      }

      final amountField = AppTextField(
        controller: _amountCtrl,
        label: 'Payment Amount (\$)',
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        prefixIcon: const Icon(Icons.attach_money),
        onChanged: (v) {
          _ctrl.paymentAmount.value = double.tryParse(v) ?? 0.0;
        },
      );

      final methodDropdown = DropdownButtonFormField<String>(
        initialValue: _ctrl.paymentMethod.value,
        isExpanded: true,
        decoration: const InputDecoration(
            labelText: 'Payment Method',
            prefixIcon: Icon(Icons.payment)),
        items: const [
          DropdownMenuItem(value: 'CASH', child: Text('Cash')),
          DropdownMenuItem(
              value: 'POS', child: Text('POS / Terminal Card')),
          DropdownMenuItem(
              value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
          DropdownMenuItem(
              value: 'ONLINE', child: Text('Online / Portal')),
        ],
        onChanged: (v) {
          if (v != null) _ctrl.paymentMethod.value = v;
        },
      );

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(isPhone ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv.patientName, style: AppTextStyles.h3),
                              Text('Invoice ID: #${inv.invoiceId}',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _ctrl.clearSelection),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Itemized Hospital Charges',
                        style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    ...inv.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.description} (x${item.quantity})',
                                    style: AppTextStyles.bodyMedium),
                              ),
                              const SizedBox(width: 8),
                              Text('\$${item.total.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${inv.total.toStringAsFixed(2)}',
                            style: AppTextStyles.h4
                                .copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid:',
                            style: TextStyle(color: AppColors.success)),
                        Text('\$${inv.amountPaid.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance Due:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('\$${inv.balance.toStringAsFixed(2)}',
                            style: AppTextStyles.h3.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Record Payment Transaction', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            if (isPhone) ...[
              amountField,
              const SizedBox(height: 14),
              methodDropdown,
            ] else ...[
              Row(
                children: [
                  Expanded(child: amountField),
                  const SizedBox(width: 16),
                  Expanded(child: methodDropdown),
                ],
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              controller: _refCtrl,
              label: 'Transaction Reference / Receipt ID',
              hint: 'e.g. POS-982348 or Bank Ref #',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              onChanged: (v) => _ctrl.transactionRef.value = v,
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
                  text: 'Process Payment & Issue Receipt',
                  onPressed: () => _ctrl.processPayment(
                    staffId: _auth.user?.uid ?? '',
                    staffName: _auth.userName,
                  ),
                  isLoading: _ctrl.isLoading.value,
                  isFullWidth: true,
                  icon: Icons.check_circle_rounded,
                )),
            if (_ctrl.selectedInvoicePayments.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text('Prior Transactions for this Bill',
                  style: AppTextStyles.h4),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ctrl.selectedInvoicePayments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) {
                  final p = _ctrl.selectedInvoicePayments[idx];
                  return ListTile(
                    leading:
                        const Icon(Icons.receipt, color: AppColors.primary),
                    title: Text(
                        '\$${p.amount.toStringAsFixed(2)} via ${p.paymentMethod}'),
                    subtitle: Text(
                        'Ref: ${p.transactionReference} • Received by: ${p.receivedByName}'),
                    trailing: Text(DateFormat.yMMMd().format(p.paymentDate)),
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }
}
