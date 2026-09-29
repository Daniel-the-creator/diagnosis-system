import 'package:cloud_firestore/cloud_firestore.dart';

/// Pharmacy medication inventory record.
class MedicationModel {
  final String medicationId;
  final String drugName;
  final String genericName;
  final String category;       // e.g. 'Antibiotic', 'Analgesic', 'Antihypertensive'
  final String batchNumber;
  final int quantity;          // Current stock
  final double unitPrice;
  final DateTime? expiryDate;
  final String supplier;
  final int minimumStockLevel; // Threshold for low-stock alert
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationModel({
    required this.medicationId,
    required this.drugName,
    this.genericName = '',
    this.category = '',
    this.batchNumber = '',
    required this.quantity,
    this.unitPrice = 0.0,
    this.expiryDate,
    this.supplier = '',
    this.minimumStockLevel = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= minimumStockLevel;

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isNearExpiry {
    if (expiryDate == null) return false;
    final daysUntilExpiry =
        expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }

  bool get isOutOfStock => quantity <= 0;
  int get stockQuantity => quantity;
  String get name => drugName;

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      medicationId: data['medicationId'] as String? ?? doc.id,
      drugName: data['drugName'] as String? ?? '',
      genericName: data['genericName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      supplier: data['supplier'] as String? ?? '',
      minimumStockLevel: data['minimumStockLevel'] as int? ?? 10,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'medicationId': medicationId,
        'drugName': drugName,
        'genericName': genericName,
        'category': category,
        'batchNumber': batchNumber,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'expiryDate':
            expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
        'supplier': supplier,
        'minimumStockLevel': minimumStockLevel,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  MedicationModel copyWith({
    String? medicationId,
    String? drugName,
    String? genericName,
    String? category,
    String? batchNumber,
    int? quantity,
    int? stockQuantity,
    double? unitPrice,
    DateTime? expiryDate,
    String? supplier,
    int? minimumStockLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MedicationModel(
        medicationId: medicationId ?? this.medicationId,
        drugName: drugName ?? this.drugName,
        genericName: genericName ?? this.genericName,
        category: category ?? this.category,
        batchNumber: batchNumber ?? this.batchNumber,
        quantity: stockQuantity ?? quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        expiryDate: expiryDate ?? this.expiryDate,
        supplier: supplier ?? this.supplier,
        minimumStockLevel: minimumStockLevel ?? this.minimumStockLevel,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'MedicationModel($medicationId, $drugName, qty=$quantity)';
}
