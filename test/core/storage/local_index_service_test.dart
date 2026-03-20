import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/storage/local_index_service.dart';
import 'package:obsidian/core/storage/local_storage_service.dart';
import 'package:obsidian/core/sync/models/sync_entry.dart';
import 'package:path/path.dart' as p;

class _FakeLocalStorageService extends LocalStorageService {
  _FakeLocalStorageService(this._vaultDir);

  final Directory _vaultDir;

  @override
  Future<Directory> getVaultDirectory() async {
    if (!await _vaultDir.exists()) {
      await _vaultDir.create(recursive: true);
    }
    return _vaultDir;
  }
}

void main() {
  group('LocalIndexService', () {
    late Directory tempDir;
    late LocalIndexService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'vaultclient_index_test_',
      );
      service = LocalIndexService(_FakeLocalStorageService(tempDir));
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('save and load entries successfully', () async {
      final entries = <SyncEntry>[
        SyncEntry(
          relativePath: 'notes/a.md',
          isDir: false,
          size: 123,
          remoteMTimeMillis: 1000,
          localMTimeMillis: 1200,
          etag: 'etag-a',
          lastSyncedAtMillis: 2000,
        ),
        SyncEntry(
          relativePath: 'notes',
          isDir: true,
          size: 0,
          remoteMTimeMillis: 900,
          localMTimeMillis: 1100,
          etag: null,
          lastSyncedAtMillis: 2000,
        ),
      ];

      await service.saveEntries(entries);
      final loaded = await service.loadEntries();

      expect(loaded.length, 2);
      expect(
        loaded.map((e) => e.relativePath),
        containsAll(<String>['notes', 'notes/a.md']),
      );
      expect(
        loaded.firstWhere((e) => e.relativePath == 'notes/a.md').etag,
        'etag-a',
      );
    });

    test('returns empty entries when index file is corrupted', () async {
      final indexFile = File(p.join(tempDir.path, '.vault_index.json'));
      await indexFile.writeAsString('{not-json');

      final loaded = await service.loadEntries();

      expect(loaded, isEmpty);
    });
  });
}
