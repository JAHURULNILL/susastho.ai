enum OfflineQueueItemType {
  mealScan,
  menuScan,
  receiptScan,
}

class OfflineQueueItem {
  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
  });

  final String id;
  final OfflineQueueItemType type;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'] as String? ?? '',
      type: OfflineQueueItemType.values.byName(
        json['type'] as String? ?? OfflineQueueItemType.mealScan.name,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'payload': payload,
    };
  }
}
