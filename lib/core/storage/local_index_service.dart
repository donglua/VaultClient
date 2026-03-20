import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../sync/models/sync_entry.dart';
import 'local_storage_service.dart';

class LocalIndexService {
  static const String _indexFileName = '.vault_index.json';

  final LocalStorageService _localStorage;

  LocalIndexService(this._localStorage);

  Future<Map<String, SyncEntry>> loadEntryMap() async {
    final entries = await loadEntries();
    return {for (final entry in entries) entry.relativePath: entry};
  }

  Future<List<SyncEntry>> loadEntries() async {
    final file = await _getIndexFile();
    if (!await file.exists()) {
      return [];
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return [];
      }

      final data = decoded['entries'];
      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map((e) => SyncEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (_) {
      // Index corruption should not break sync; start fresh.
      return [];
    }
  }

  Future<void> saveEntries(Iterable<SyncEntry> entries) async {
    final file = await _getIndexFile();
    await file.parent.create(recursive: true);

    final sorted = entries.toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));

    final payload = {
      'version': 1,
      'entries': sorted.map((e) => e.toJson()).toList(growable: false),
    };

    await file.writeAsString(jsonEncode(payload));
  }

  Future<void> upsertEntry(SyncEntry entry) async {
    final map = await loadEntryMap();
    map[entry.relativePath] = entry;
    await saveEntries(map.values);
  }

  Future<void> removeEntry(String relativePath) async {
    final map = await loadEntryMap();
    map.remove(relativePath);
    await saveEntries(map.values);
  }

  Future<void> bulkReplace(Iterable<SyncEntry> entries) async {
    await saveEntries(entries);
  }

  Future<File> _getIndexFile() async {
    final vaultDir = await _localStorage.getVaultDirectory();
    return File(p.join(vaultDir.path, _indexFileName));
  }
}
