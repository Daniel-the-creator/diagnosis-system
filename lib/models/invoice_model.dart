import 'package:cloud_firestore/cloud_firestore.dart';

/// A single line item on an invoice.
class InvoiceItemModel {
  final String description;
  final String category; // CONSULTATION | LABORATORY | XRAY | SCAN | MEDICATION | ADMISSION | BED | OTHER
  final double unitPrice;
  final int quantity;
  final double total;

  const InvoiceItemModel({
    required this.description,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) =>
      InvoiceItemModel(
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? 'OTHER',
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: map['quantity'] as int? ?? 1,
        total: (map['total'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'category': category,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'total': total,
      };
}

/// Billing invoice for a patient visit.
/// Status flow: PENDING -> PARTIALLY_PAID -> PAID
///              PENDING | PARTIALLY_PAID -> REFUNDED | CANCELLED
class InvoiceModel {
  final String invoiceId;
  final String patientId;
  final String patientName;
  final String visitId;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double discount;
  final double total;
  final double amountPaid;
  final double balance;

  /// PENDING | PARTIALLY_PAID | PAID | REFUNDED | CANCELLED
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.invoiceId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.amountPaid = 0.0,
    required this.balance,
    this.status = 'PENDING',
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isPartiallyPaid => status == 'PARTIALLY_PAID';

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List? ?? [];
    return InvoiceModel(
      invoiceId: data['invoiceId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      items: rawItems
          .map((e) => InvoiceItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'PENDING',
      notes: data['notes'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'invoiceId': invoiceId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'amountPaid': amountPaid,
        'balance': balance,
        'status': status,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  InvoiceModel copyWith({
    String? invoiceId,
    String? patientId,
    String? patientName,
    String? visitId,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? discount,
    double? total,
    double? amountPaid,
    double? balance,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      InvoiceModel(
        invoiceId: invoiceId ?? this.invoiceId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        total: total ?? this.total,
        amountPaid: amountPaid ?? this.amountPaid,
        balance: balance ?? this.balance,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'InvoiceModel($invoiceId, visit=$visitId, total=$total, status=$status)';
}
