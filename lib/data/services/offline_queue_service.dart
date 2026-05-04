import '../models/offline_queue_item.dart';
import 'local_storage_service.dart';

class OfflineQueueService {
  OfflineQueueService(this._storage);

  final LocalStorageService _storage;
  static const _queueKey = 'offline_queue_items';

  Future<List<OfflineQueueItem>> loadQueue() async {
    final items = await _storage.readJsonList(_queueKey);
    return items.map(OfflineQueueItem.fromJson).toList();
  }

  Future<void> enqueue(OfflineQueueItem item) async {
    final items = await loadQueue();
    await _storage.saveJsonList(
      _queueKey,
      [...items, item].map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> remove(String id) async {
    final items = await loadQueue();
    await _storage.saveJsonList(
      _queueKey,
      items.where((entry) => entry.id != id).map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> clear() async {
    await _storage.remove(_queueKey);
  }
}
