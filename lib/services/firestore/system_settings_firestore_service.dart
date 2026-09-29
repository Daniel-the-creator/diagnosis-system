import '../../core/constants/firestore_constants.dart';
import '../../models/system_settings_model.dart';
import 'firestore_service.dart';

/// Firestore persistence service for system configuration and hospital preferences.
class SystemSettingsFirestoreService {
  SystemSettingsFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.settingsCollection;
  static const String _docId = 'general';

  /// Fetches system settings or returns default if not initialized
  Future<SystemSettingsModel> getSettings() async {
    try {
      final doc = await _fs.getDoc(_col, _docId);
      if (!doc.exists) {
        final def = SystemSettingsModel.defaultSettings();
        await _fs.setDoc(_col, _docId, def.toFirestore());
        return def;
      }
      return SystemSettingsModel.fromFirestore(doc);
    } catch (_) {
      return SystemSettingsModel.defaultSettings();
    }
  }

  /// Streams real-time system configuration updates
  Stream<SystemSettingsModel> streamSettings() {
    return _fs.db.collection(_col).doc(_docId).snapshots().map((snap) {
      if (!snap.exists) return SystemSettingsModel.defaultSettings();
      return SystemSettingsModel.fromFirestore(snap);
    });
  }

  /// Updates system settings
  Future<void> updateSettings(SystemSettingsModel settings) async {
    await _fs.setDoc(
      _col,
      _docId,
      settings.copyWith(updatedAt: DateTime.now()).toFirestore(),
      merge: true,
    );
  }
}
