import 'dart:async';
import 'package:get/get.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../repositories/billing_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/notification_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for Account Officer / Billing desk.
class BillingController extends GetxController {
  BillingController(
    this._billingRepo,
    this._visitRepo, {
    NotificationRepository? notificationRepo,
  }) : _notificationRepo = notificationRepo ??
            (Get.isRegistered<NotificationRepository>()
                ? Get.find<NotificationRepository>()
                : null);

  final BillingRepository _billingRepo;
  final VisitRepository _visitRepo;
  final NotificationRepository? _notificationRepo;

  final RxList<InvoiceModel> allInvoices = <InvoiceModel>[].obs;
  final RxList<InvoiceModel> pendingInvoices = <InvoiceModel>[].obs;
  final Rx<InvoiceModel?> selectedInvoice = Rx<InvoiceModel?>(null);
  final RxList<PaymentModel> selectedInvoicePayments = <PaymentModel>[].obs;

  // Filter: 'PENDING' | 'PAID' | 'ALL'
  final RxString filterStatus = 'PENDING'.obs;

  // Payment form state
  final RxDouble paymentAmount = 0.0.obs;
  final RxString paymentMethod =
      'CASH'.obs; // 'CASH' | 'POS' | 'BANK_TRANSFER' | 'ONLINE'
  final RxString transactionRef = ''.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _invSub;
  StreamSubscription? _paySub;

  @override
  void onInit() {
    super.onInit();
    _setupStream();
  }

  @override
  void onClose() {
    _invSub?.cancel();
    _paySub?.cancel();
    super.onClose();
  }

  void setFilter(String status) {
    filterStatus.value = status;
  }

  List<InvoiceModel> get displayedInvoices {
    final status = filterStatus.value;
    if (status == 'PAID') {
      return allInvoices.where((i) => i.status == 'PAID').toList();
    } else if (status == 'PENDING') {
      return allInvoices
          .where((i) => i.status == 'PENDING' || i.status == 'PARTIALLY_PAID')
          .toList();
    }
    return allInvoices.toList();
  }

  double get totalRevenue =>
      allInvoices.fold(0.0, (sum, i) => sum + i.amountPaid);

  double get totalPendingBalance => allInvoices
      .where((i) => i.status == 'PENDING' || i.status == 'PARTIALLY_PAID')
      .fold(0.0, (sum, i) => sum + i.balance);

  void _setupStream() {
    _invSub?.cancel();
    _invSub = _billingRepo.streamAllInvoices().listen((list) {
      allInvoices.assignAll(list);
      pendingInvoices.assignAll(
        list.where(
            (i) => i.status == 'PENDING' || i.status == 'PARTIALLY_PAID'),
      );
    });
  }

  void selectInvoice(InvoiceModel invoice) {
    selectedInvoice.value = invoice;
    paymentAmount.value = invoice.balance;
    transactionRef.value = '';

    _paySub?.cancel();
    _paySub = _billingRepo
        .streamInvoicePayments(invoice.invoiceId)
        .listen((payments) {
      selectedInvoicePayments.assignAll(payments);
    });
  }

  Future<bool> processPayment({
    required String staffId,
    required String staffName,
  }) async {
    final inv = selectedInvoice.value;
    if (inv == null) return false;

    if (paymentAmount.value <= 0) {
      errorMessage.value = 'Payment amount must be greater than zero.';
      return false;
    }

    if (paymentAmount.value > inv.balance) {
      errorMessage.value =
          'Payment amount cannot exceed remaining balance of \$${inv.balance.toStringAsFixed(2)}.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final payId = _billingRepo.generatePaymentId();
      final payment = PaymentModel(
        paymentId: payId,
        invoiceId: inv.invoiceId,
        patientId: inv.patientId,
        patientName: inv.patientName,
        visitId: inv.visitId,
        amount: paymentAmount.value,
        paymentMethod: paymentMethod.value,
        transactionReference: transactionRef.value.trim().isNotEmpty
            ? transactionRef.value.trim()
            : 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        receivedBy: staffId,
        receivedByName: staffName,
        paymentDate: DateTime.now(),
        status: 'SUCCESS',
      );

      await _billingRepo.recordPayment(payment: payment, invoice: inv);

      // Check if invoice is fully paid and advance visit state if waiting on payment
      if (paymentAmount.value >= inv.balance) {
        await _visitRepo.updateVisit(inv.visitId, {
          'careStage': 'PAID',
        });
      }

      // Notify patient
      if (_notificationRepo != null && inv.patientId.isNotEmpty) {
        await _notificationRepo.notify(
          recipientId: inv.patientId,
          recipientType: 'patient',
          title: 'Payment Received',
          body:
              'Payment of \$${paymentAmount.value.toStringAsFixed(2)} via ${paymentMethod.value} was successfully processed.',
          type: 'PAYMENT_RECEIVED',
          relatedId: inv.invoiceId,
        );
      }

      Get.snackbar(
        'Payment Recorded',
        'Successfully processed payment of \$${paymentAmount.value.toStringAsFixed(2)}.',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload invoice details
      final updatedInv = await _billingRepo.getInvoiceById(inv.invoiceId);
      if (updatedInv != null) {
        selectedInvoice.value = updatedInv;
        paymentAmount.value = updatedInv.balance;
      }
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearSelection() {
    selectedInvoice.value = null;
    selectedInvoicePayments.clear();
  }
}
