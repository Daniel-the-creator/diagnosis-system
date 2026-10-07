import 'package:get/get.dart';
import '../models/admission_models.dart';
import '../models/discharge_model.dart';
import '../repositories/admission_repository.dart';
import '../repositories/discharge_repository.dart';
import '../repositories/notification_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for the Admission Officer dashboard.
class AdmissionController extends GetxController {
  AdmissionController(
    this._admissionRepo,
    this._dischargeRepo, {
    NotificationRepository? notificationRepo,
  }) : _notificationRepo = notificationRepo ??
            (Get.isRegistered<NotificationRepository>()
                ? Get.find<NotificationRepository>()
                : null);

  final AdmissionRepository _admissionRepo;
  final DischargeRepository _dischargeRepo;
  final NotificationRepository? _notificationRepo;

  final RxList<AdmissionRequestModel> admissionRequests =
      <AdmissionRequestModel>[].obs;
  final RxList<WardModel> wards = <WardModel>[].obs;
  final RxList<BedModel> beds = <BedModel>[].obs;

  final Rx<String?> selectedWardId = Rx<String?>(null);
  final Rx<AdmissionRequestModel?> selectedRequest =
      Rx<AdmissionRequestModel?>(null);
  final Rx<BedModel?> selectedBed = Rx<BedModel?>(null);

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  void _setupStreams() {
    _admissionRepo.streamActiveAdmissionRequests().listen((list) {
      admissionRequests.assignAll(list);
    });

    _admissionRepo.streamWards().listen((list) {
      wards.assignAll(list);
    });

    _streamBeds();
  }

  void filterByWard(String? wardId) {
    selectedWardId.value = wardId;
    _streamBeds();
  }

  void _streamBeds() {
    _admissionRepo.streamBeds(wardId: selectedWardId.value).listen((list) {
      beds.assignAll(list);
    });
  }

  void selectAdmissionRequest(AdmissionRequestModel req) {
    selectedRequest.value = req;
    selectedBed.value = null;
  }

  void selectBed(BedModel bed) {
    selectedBed.value = bed;
  }

  Future<bool> assignBedToPatient() async {
    final req = selectedRequest.value;
    final bed = selectedBed.value;

    if (req == null) {
      errorMessage.value = 'Please select an admission request.';
      return false;
    }
    if (bed == null) {
      errorMessage.value = 'Please select a bed to assign.';
      return false;
    }
    if (!bed.isAvailable) {
      errorMessage.value = 'Selected bed is not available (${bed.status}).';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final ward = wards.firstWhereOrNull((w) => w.wardId == bed.wardId);
      final wardName = ward?.name ?? bed.wardName;

      await _admissionRepo.assignBed(
        bedId: bed.bedId,
        admissionRequestId: req.admissionRequestId,
        patientId: req.patientId,
        patientName: req.patientName,
        visitId: req.visitId,
        wardId: bed.wardId,
        wardName: wardName,
        bedNumber: bed.bedNumber,
      );

      // Notify patient
      if (_notificationRepo != null && req.patientId.isNotEmpty) {
        await _notificationRepo.notify(
          recipientId: req.patientId,
          recipientType: 'patient',
          title: 'Bed Assigned',
          body: 'You have been admitted to $wardName, Bed ${bed.bedNumber}.',
          type: 'BED_ASSIGNED',
          relatedId: req.admissionRequestId,
        );
      }

      Get.snackbar(
        'Bed Assigned',
        'Patient ${req.patientName} assigned to $wardName (Bed ${bed.bedNumber}).',
        snackPosition: SnackPosition.BOTTOM,
      );

      selectedRequest.value = null;
      selectedBed.value = null;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> releaseBed(String bedId) async {
    isLoading.value = true;
    try {
      await _admissionRepo.releaseBed(bedId);
      Get.snackbar('Bed Released', 'Bed is now marked as AVAILABLE.');
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> processDischarge({
    required String visitId,
    required String patientId,
    required String patientName,
    String? admissionId,
    String? bedId,
    required String doctorId,
    required String doctorName,
    required String dischargeSummary,
    List<String> medications = const [],
    String followUpInstructions = '',
    required String dischargedBy,
    required String dischargedByName,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final disId = _dischargeRepo.generateDischargeId();
      final discharge = DischargeModel(
        dischargeId: disId,
        patientId: patientId,
        patientName: patientName,
        visitId: visitId,
        admissionId: admissionId,
        doctorId: doctorId,
        doctorName: doctorName,
        dischargeSummary: dischargeSummary,
        medications: medications,
        followUpInstructions: followUpInstructions,
        dischargedAt: DateTime.now(),
        dischargedBy: dischargedBy,
        dischargedByName: dischargedByName,
      );

      await _dischargeRepo.processDischarge(
        discharge: discharge,
        admissionId: admissionId,
        bedId: bedId,
      );

      if (_notificationRepo != null && patientId.isNotEmpty) {
        await _notificationRepo.notify(
          recipientId: patientId,
          recipientType: 'patient',
          title: 'Discharge Completed',
          body:
              'You have been formally discharged. Take care and follow your discharge instructions.',
          type: 'DISCHARGE_READY',
          relatedId: disId,
        );
      }

      Get.snackbar(
          'Patient Discharged', 'Discharge record saved and bed released.');
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  List<BedModel> get availableBeds => beds.where((b) => b.isAvailable).toList();
  List<BedModel> get occupiedBeds => beds.where((b) => b.isOccupied).toList();
}
