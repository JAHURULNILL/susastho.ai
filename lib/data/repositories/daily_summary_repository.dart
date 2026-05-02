import '../models/daily_summary.dart';
import '../services/local_storage_service.dart';

class DailySummaryRepository {
  DailySummaryRepository(this._storage);

  final LocalStorageService _storage;

  Future<DailySummary> loadToday() async {
    final key = _keyFor(DateTime.now());
    final json = await _storage.readJson(key);
    if (json == null) {
      return DailySummary(dateKey: _formatDate(DateTime.now()));
    }
    return DailySummary.fromJson(json);
  }

  Future<void> save(DailySummary summary) async {
    await _storage.saveJson(_keyFor(DateTime.now()), summary.toJson());
  }

  String _keyFor(DateTime date) => 'daily_summary_${_formatDate(date)}';

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
