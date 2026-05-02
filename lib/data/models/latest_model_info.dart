class LatestModelInfo {
  const LatestModelInfo({
    required this.provider,
    required this.available,
    this.id,
    this.name,
    this.version,
    this.summary,
    this.reason,
  });

  final String provider;
  final bool available;
  final String? id;
  final String? name;
  final String? version;
  final String? summary;
  final String? reason;

  factory LatestModelInfo.fromJson(Map<String, dynamic> json) {
    return LatestModelInfo(
      provider: json['provider'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      id: json['id'] as String?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      summary: json['summary'] as String?,
      reason: json['reason'] as String?,
    );
  }
}
