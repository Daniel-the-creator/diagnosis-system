import '../models/system_settings_model.dart';
import '../services/firestore/system_settings_firestore_service.dart';

/// Repository for retrieving and updating system-wide hospital settings.
class SystemSettingsRepository {
  SystemSettingsRepository(this._service);
  final SystemSettingsFirestoreService _service;

  Future<SystemSettingsModel> getSettings() => _service.getSettings();

  Stream<SystemSettingsModel> streamSettings() => _service.streamSettings();

  Future<void> updateSettings(SystemSettingsModel settings) =>
      _service.updateSettings(settings);
}
