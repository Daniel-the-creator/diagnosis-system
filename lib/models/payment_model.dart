import 'package:cloud_firestore/cloud_firestore.dart';

/// A payment transaction record linked to an invoice.
/// One invoice can have multiple PaymentModels (partial payments allowed).
class PaymentModel {
  final String paymentId;
  final String invoiceId;
  final String patientId;
  final String patientName;
  final String visitId;
  final double amount;
  /// CASH | POS | BANK_TRANSFER | ONLINE
  final String paymentMethod;
  final String? transactionReference;
  final String receivedBy;     // Staff uid who received payment
  final String receivedByName; // Display name
  final DateTime paymentDate;
  /// COMPLETED | REVERSED | PENDING_VERIFICATION | SUCCESS
  final String status;

  const PaymentModel({
    required this.paymentId,
    required this.invoiceId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.amount,
    required this.paymentMethod,
    this.transactionReference,
    required this.receivedBy,
    this.receivedByName = '',
    required this.paymentDate,
    this.status = 'COMPLETED',
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      paymentId: data['paymentId'] as String? ?? doc.id,
      invoiceId: data['invoiceId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? 'CASH',
      transactionReference: data['transactionReference'] as String?,
      receivedBy: data['receivedBy'] as String? ?? '',
      receivedByName: data['receivedByName'] as String? ?? '',
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'COMPLETED',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'paymentId': paymentId,
        'invoiceId': invoiceId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionReference': transactionReference,
        'receivedBy': receivedBy,
        'receivedByName': receivedByName,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'status': status,
      };

  @override
  String toString() =>
      'PaymentModel($paymentId, invoice=$invoiceId, amount=$amount, method=$paymentMethod)';
}
