import 'package:get/get.dart';
import '../models/queue_item_model.dart';
import '../repositories/queue_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Manages real-time queue state for a department.
class QueueController extends GetxController {
  QueueController(this._queueRepo, {required this.departmentCode});
  final QueueRepository _queueRepo;
  final String departmentCode;

  final RxList<QueueItemModel> activeQueue = <QueueItemModel>[].obs;
  final RxList<QueueItemModel> completedToday = <QueueItemModel>[].obs;
  final Rx<QueueItemModel?> currentlyServing = Rx<QueueItemModel?>(null);
  final RxInt waitingCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _queueRepo
        .streamActiveQueue(departmentCode)
        .listen((items) {
          activeQueue.assignAll(items);
          currentlyServing.value = items
              .where((i) => i.status == QueueStatus.inProgress)
              .firstOrNull;
          waitingCount.value = items
              .where((i) => i.status == QueueStatus.waiting)
              .length;
        });
    _queueRepo
        .streamCompletedToday(departmentCode)
        .listen((items) => completedToday.assignAll(items));
  }

  List<QueueItemModel> get waitingItems =>
      activeQueue.where((i) => i.status == QueueStatus.waiting).toList();

  List<QueueItemModel> get calledItems =>
      activeQueue.where((i) => i.status == QueueStatus.called).toList();

  Future<void> callNext(String staffId) async {
    if (currentlyServing.value != null) {
      Get.snackbar(
        'Cannot Call Next',
        'Please complete or skip the current patient first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isLoading.value = true;
    try {
      await _queueRepo.callNext(departmentCode, staffId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> callPatient(String queueId, String staffId) async {
    isLoading.value = true;
    try {
      await _queueRepo.callPatient(queueId, staffId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startService(String queueId) async {
    isLoading.value = true;
    try {
      await _queueRepo.startService(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeService(String queueId) async {
    isLoading.value = true;
    try {
      await _queueRepo.completeService(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> skipPatient(String queueId) async {
    try {
      await _queueRepo.skipPatient(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> markNoShow(String queueId) async {
    try {
      await _queueRepo.markNoShow(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> cancelItem(String queueId) async {
    try {
      await _queueRepo.cancelQueueItem(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> recallPatient(String queueId, String staffId) async {
    try {
      await _queueRepo.recallPatient(queueId, staffId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  void clearError() => errorMessage.value = '';
}
