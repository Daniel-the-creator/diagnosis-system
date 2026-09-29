import 'package:get/get.dart';
import '../models/queue_item_model.dart';
import '../repositories/queue_repository.dart';
import '../services/audio/audio_announcement_service.dart';

/// Controller powering the full-screen hospital waiting area digital display board
/// with real-time audio announcements and strict privacy compliance.
class DigitalQueueDisplayController extends GetxController {
  DigitalQueueDisplayController(
    this._queueRepo, [
    AudioAnnouncementService? audioService,
  ]) : _audioService = audioService ?? (Get.isRegistered<AudioAnnouncementService>()
            ? Get.find<AudioAnnouncementService>()
            : AudioAnnouncementService());

  final QueueRepository _queueRepo;
  final AudioAnnouncementService _audioService;

  final RxString selectedDept = 'ALL'.obs;
  final RxList<QueueItemModel> activeQueue = <QueueItemModel>[].obs;
  final Rx<QueueItemModel?> currentlyServing = Rx<QueueItemModel?>(null);
  final RxList<QueueItemModel> upNextList = <QueueItemModel>[].obs;

  final RxBool hasNewCall = false.obs;
  final RxBool audioEnabled = true.obs;
  String? _lastCalledId;
  dynamic _streamSub;

  @override
  void onInit() {
    super.onInit();
    audioEnabled.value = _audioService.isEnabled;
    _setupStream();
  }

  @override
  void onClose() {
    try {
      _streamSub?.cancel();
    } catch (_) {}
    super.onClose();
  }

  void toggleAudio() {
    final next = !audioEnabled.value;
    audioEnabled.value = next;
    _audioService.setEnabled(next);
  }

  void setDepartment(String deptCode) {
    selectedDept.value = deptCode;
    _setupStream();
  }

  void _setupStream() {
    _streamSub?.cancel();
    final dept = selectedDept.value == 'ALL' ? '' : selectedDept.value;
    _streamSub = _queueRepo.streamActiveQueue(dept).listen((items) {
      activeQueue.assignAll(items);

      final serving = items.firstWhereOrNull(
        (i) => i.status == QueueStatus.inProgress || i.status == QueueStatus.called,
      );

      if (serving != null && serving.queueId != _lastCalledId) {
        _lastCalledId = serving.queueId;
        _triggerCallAnimation();
        _announce(serving);
      }

      currentlyServing.value = serving;

      final upcoming = items
          .where((i) => i.status == QueueStatus.waiting)
          .take(6)
          .toList();
      upNextList.assignAll(upcoming);
    });
  }

  void _announce(QueueItemModel item) {
    if (!audioEnabled.value) return;
    final room = item.assignedRoomName ??
        (item.assignedRoomNumber != null ? 'Room ${item.assignedRoomNumber}' : 'Consultation Room');
    _audioService.announcePatientCall(
      queueNumber: item.displayQueueNumber,
      roomName: room,
    );
  }

  void _triggerCallAnimation() {
    hasNewCall.value = true;
    Future.delayed(const Duration(seconds: 4), () {
      hasNewCall.value = false;
    });
  }
}
