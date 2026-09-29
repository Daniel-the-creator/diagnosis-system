import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/invoice_model.dart';
import '../../models/payment_model.dart';
import 'firestore_service.dart';

/// Firestore operations for invoices and payments collections.
class BillingFirestoreService {
  BillingFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _invCol = FirestoreConstants.invoicesCollection;
  static const String _payCol = FirestoreConstants.paymentsCollection;

  String generateInvoiceId() => _fs.generateId(_invCol);
  String generatePaymentId() => _fs.generateId(_payCol);

  // ── Invoices ───────────────────────────────────────────────────

  Future<void> saveInvoice(InvoiceModel invoice) =>
      _fs.setDoc(_invCol, invoice.invoiceId, invoice.toFirestore());

  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    final doc = await _fs.getDoc(_invCol, invoiceId);
    if (!doc.exists) return null;
    return InvoiceModel.fromFirestore(doc);
  }

  Future<InvoiceModel?> getInvoiceByVisitId(String visitId) async {
    final snap = await _fs.db
        .collection(_invCol)
        .where('visitId', isEqualTo: visitId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InvoiceModel.fromFirestore(snap.docs.first);
  }

  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> data) =>
      _fs.updateDoc(_invCol, invoiceId, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Atomically record a payment and update the invoice balance.
  Future<void> recordPayment({
    required PaymentModel payment,
    required InvoiceModel invoice,
  }) async {
    final paymentRef =
        _fs.db.collection(_payCol).doc(payment.paymentId);
    final invoiceRef =
        _fs.db.collection(_invCol).doc(invoice.invoiceId);

    await _fs.runTransaction<void>((txn) async {
      final freshInvoiceSnap = await txn.get(invoiceRef);
      if (!freshInvoiceSnap.exists) return;

      final currentPaid =
          (freshInvoiceSnap.data()!['amountPaid'] as num?)?.toDouble() ?? 0.0;
      final total =
          (freshInvoiceSnap.data()!['total'] as num?)?.toDouble() ?? 0.0;
      final newPaid = currentPaid + payment.amount;
      final newBalance = total - newPaid;

      String newStatus;
      if (newBalance <= 0) {
        newStatus = 'PAID';
      } else if (newPaid > 0) {
        newStatus = 'PARTIALLY_PAID';
      } else {
        newStatus = 'PENDING';
      }

      txn.set(paymentRef, payment.toFirestore());
      txn.update(invoiceRef, {
        'amountPaid': newPaid,
        'balance': newBalance < 0 ? 0.0 : newBalance,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Stream invoice for a visit (real-time billing status).
  Stream<InvoiceModel?> streamInvoiceForVisit(String visitId) =>
      _fs.db
          .collection(_invCol)
          .where('visitId', isEqualTo: visitId)
          .limit(1)
          .snapshots()
          .map((snap) {
            if (snap.docs.isEmpty) return null;
            return InvoiceModel.fromFirestore(snap.docs.first);
          });

  /// Stream all invoices for a patient.
  Stream<List<InvoiceModel>> streamPatientInvoices(String patientId) =>
      _fs.db
          .collection(_invCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(InvoiceModel.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });

  /// Stream all pending/partial invoices (Account Officer queue).
  Stream<List<InvoiceModel>> streamPendingInvoices() =>
      _fs.db
          .collection(_invCol)
          .where('status', whereIn: ['PENDING', 'PARTIALLY_PAID'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map(InvoiceModel.fromFirestore).toList());

  /// Stream all invoices across the hospital (all statuses).
  Stream<List<InvoiceModel>> streamAllInvoices() =>
      _fs.db
          .collection(_invCol)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map(InvoiceModel.fromFirestore).toList());

  // ── Payments ───────────────────────────────────────────────────

  Stream<List<PaymentModel>> streamInvoicePayments(String invoiceId) =>
      _fs.db
          .collection(_payCol)
          .where('invoiceId', isEqualTo: invoiceId)
          .orderBy('paymentDate')
          .snapshots()
          .map((snap) =>
              snap.docs.map(PaymentModel.fromFirestore).toList());

  Stream<List<PaymentModel>> streamPatientPayments(String patientId) =>
      _fs.db
          .collection(_payCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(PaymentModel.fromFirestore).toList();
            list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
            return list;
          });
}
