class SyncEntry {
  final String relativePath;
  final bool isDir;
  final int size;
  final int? remoteMTimeMillis;
  final int? localMTimeMillis;
  final String? etag;
  final int lastSyncedAtMillis;

  const SyncEntry({
    required this.relativePath,
    required this.isDir,
    required this.size,
    required this.remoteMTimeMillis,
    required this.localMTimeMillis,
    required this.etag,
    required this.lastSyncedAtMillis,
  });

  SyncEntry copyWith({
    String? relativePath,
    bool? isDir,
    int? size,
    int? remoteMTimeMillis,
    int? localMTimeMillis,
    String? etag,
    int? lastSyncedAtMillis,
  }) {
    return SyncEntry(
      relativePath: relativePath ?? this.relativePath,
      isDir: isDir ?? this.isDir,
      size: size ?? this.size,
      remoteMTimeMillis: remoteMTimeMillis ?? this.remoteMTimeMillis,
      localMTimeMillis: localMTimeMillis ?? this.localMTimeMillis,
      etag: etag ?? this.etag,
      lastSyncedAtMillis: lastSyncedAtMillis ?? this.lastSyncedAtMillis,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'relativePath': relativePath,
      'isDir': isDir,
      'size': size,
      'remoteMTimeMillis': remoteMTimeMillis,
      'localMTimeMillis': localMTimeMillis,
      'etag': etag,
      'lastSyncedAtMillis': lastSyncedAtMillis,
    };
  }

  factory SyncEntry.fromJson(Map<String, dynamic> json) {
    return SyncEntry(
      relativePath: json['relativePath'] as String,
      isDir: json['isDir'] as bool,
      size: (json['size'] as num?)?.toInt() ?? 0,
      remoteMTimeMillis: (json['remoteMTimeMillis'] as num?)?.toInt(),
      localMTimeMillis: (json['localMTimeMillis'] as num?)?.toInt(),
      etag: json['etag'] as String?,
      lastSyncedAtMillis: (json['lastSyncedAtMillis'] as num?)?.toInt() ?? 0,
    );
  }
}
