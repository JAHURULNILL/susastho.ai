import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._storage);

  final LocalStorageService _storage;
  static const _settingsKey = 'app_settings';

  Future<AppSettings> load() async {
    final json = await _storage.readJson(_settingsKey);
    if (json == null) {
      return const AppSettings();
    }
    return AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) async {
    await _storage.saveJson(_settingsKey, settings.toJson());
  }
}
