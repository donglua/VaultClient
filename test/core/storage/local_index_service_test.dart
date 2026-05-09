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

    test('upsertEntry adds and updates entries', () async {
      final entry1 = SyncEntry(
        relativePath: 'note1.md',
        isDir: false,
        size: 100,
        remoteMTimeMillis: 1000,
        localMTimeMillis: 1000,
        etag: 'tag1',
        lastSyncedAtMillis: 1000,
      );

      final entry2 = SyncEntry(
        relativePath: 'note2.md',
        isDir: false,
        size: 200,
        remoteMTimeMillis: 2000,
        localMTimeMillis: 2000,
        etag: 'tag2',
        lastSyncedAtMillis: 2000,
      );

      // 1. Add new entry
      await service.upsertEntry(entry1);
      var loaded = await service.loadEntries();
      expect(loaded.length, 1);
      expect(loaded.first.relativePath, 'note1.md');
      expect(loaded.first.size, 100);

      // 2. Add second entry
      await service.upsertEntry(entry2);
      loaded = await service.loadEntries();
      expect(loaded.length, 2);
      expect(
        loaded.map((e) => e.relativePath),
        containsAll(['note1.md', 'note2.md']),
      );

      // 3. Update existing entry
      final updatedEntry1 = entry1.copyWith(size: 150, etag: 'tag1-updated');
      await service.upsertEntry(updatedEntry1);
      loaded = await service.loadEntries();
      expect(loaded.length, 2);
      final entry = loaded.firstWhere((e) => e.relativePath == 'note1.md');
      expect(entry.size, 150);
      expect(entry.etag, 'tag1-updated');
    });

    test('returns empty entries when index file is corrupted', () async {
      final indexFile = File(p.join(tempDir.path, '.vault_index.json'));
      await indexFile.writeAsString('{not-json');

      final loaded = await service.loadEntries();

      expect(loaded, isEmpty);
    });
  });
}
