import 'dart:async';
import 'package:get/get.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../repositories/pharmacy_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/notification_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for Pharmacist dashboard: prescriptions dispensing and inventory.
class PharmacyController extends GetxController {
  PharmacyController(
    this._pharmacyRepo,
    this._visitRepo, {
    NotificationRepository? notificationRepo,
  }) : _notificationRepo = notificationRepo ??
            (Get.isRegistered<NotificationRepository>()
                ? Get.find<NotificationRepository>()
                : null);

  final PharmacyRepository _pharmacyRepo;
  final VisitRepository _visitRepo;
  final NotificationRepository? _notificationRepo;

  final RxList<PrescriptionModel> allPrescriptions = <PrescriptionModel>[].obs;
  final RxList<PrescriptionModel> pendingPrescriptions = <PrescriptionModel>[].obs;
  final RxList<MedicationModel> inventory = <MedicationModel>[].obs;
  final RxList<MedicationModel> lowStockAlerts = <MedicationModel>[].obs;

  // Filter: 'PENDING' | 'DISPENSED' | 'ALL'
  final RxString filterStatus = 'PENDING'.obs;

  final Rx<PrescriptionModel?> selectedPrescription = Rx<PrescriptionModel?>(null);
  final Rx<MedicationModel?> matchedMedication = Rx<MedicationModel?>(null);

  final RxInt dispenseQuantity = 1.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final List<StreamSubscription> _subs = [];

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.onClose();
  }

  void setFilter(String status) {
    filterStatus.value = status;
  }

  List<PrescriptionModel> get displayedPrescriptions {
    final status = filterStatus.value;
    if (status == 'DISPENSED') {
      return allPrescriptions.where((rx) => rx.status == 'DISPENSED').toList();
    } else if (status == 'PENDING') {
      return allPrescriptions
          .where((rx) => rx.status == 'PENDING' || rx.status == 'PARTIALLY_DISPENSED')
          .toList();
    }
    return allPrescriptions.toList();
  }

  void _setupStreams() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();

    _subs.add(
      _pharmacyRepo.streamAllPrescriptions().listen((list) {
        allPrescriptions.assignAll(list);
        pendingPrescriptions.assignAll(
          list.where((rx) => rx.status == 'PENDING' || rx.status == 'PARTIALLY_DISPENSED'),
        );
      }),
    );

    _subs.add(
      _pharmacyRepo.streamAllMedications().listen((list) {
        inventory.assignAll(list);
      }),
    );

    _subs.add(
      _pharmacyRepo.streamLowStockMedications().listen((list) {
        lowStockAlerts.assignAll(list);
      }),
    );
  }

  void selectPrescription(PrescriptionModel rx) {
    selectedPrescription.value = rx;
    dispenseQuantity.value = rx.remaining;

    // Try finding in inventory by name
    final match = inventory.firstWhereOrNull(
      (m) => m.drugName.toLowerCase().contains(rx.medicationName.toLowerCase()) ||
          rx.medicationName.toLowerCase().contains(m.drugName.toLowerCase()),
    );
    matchedMedication.value = match;
  }

  Future<bool> dispense({
    required String staffId,
    required String staffName,
  }) async {
    final rx = selectedPrescription.value;
    final med = matchedMedication.value;

    if (rx == null) return false;
    if (med == null) {
      errorMessage.value = 'Please select a matching inventory medication.';
      return false;
    }

    if (dispenseQuantity.value <= 0 || dispenseQuantity.value > rx.remaining) {
      errorMessage.value = 'Dispense quantity must be between 1 and ${rx.remaining}.';
      return false;
    }

    if (med.quantity < dispenseQuantity.value) {
      errorMessage.value = 'Insufficient stock. Available in inventory: ${med.quantity}.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _pharmacyRepo.dispenseMedication(
        prescriptionId: rx.prescriptionId,
        medicationId: med.medicationId,
        quantityToDispense: dispenseQuantity.value,
        dispensedBy: staffId,
        dispensedByName: staffName,
      );

      // Check if this was the last pending prescription for this visit
      final remainingRxList = await _pharmacyRepo.getPrescriptionById(rx.prescriptionId);
      if (remainingRxList != null && remainingRxList.isDispensed) {
        await _visitRepo.updateVisit(rx.visitId, {
          'careStage': 'READY_FOR_DISCHARGE',
        });
      }

      // Notify patient
      if (_notificationRepo != null && rx.patientId.isNotEmpty) {
        await _notificationRepo!.notify(
          recipientId: rx.patientId,
          recipientType: 'patient',
          title: 'Medications Dispensed',
          body: '${rx.medicationName} (${dispenseQuantity.value} units) has been dispensed and is ready for pickup.',
          type: 'PRESCRIPTION_READY',
          relatedId: rx.prescriptionId,
        );
      }

      Get.snackbar(
        'Medication Dispensed',
        'Successfully dispensed ${dispenseQuantity.value} of ${rx.medicationName}.',
        snackPosition: SnackPosition.BOTTOM,
      );

      selectedPrescription.value = null;
      matchedMedication.value = null;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restockMedication(String medicationId, int quantity) async {
    if (quantity <= 0) return;
    try {
      await _pharmacyRepo.addStock(medicationId, quantity);
      Get.snackbar('Stock Updated', 'Added $quantity units to inventory.');
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> saveMedication(MedicationModel med) async {
    try {
      await _pharmacyRepo.saveMedication(med);
      Get.snackbar('Saved', '${med.drugName} saved to inventory.');
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  void clearSelection() {
    selectedPrescription.value = null;
    matchedMedication.value = null;
  }
}
