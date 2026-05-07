import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/network/webdav_service.dart';
import 'package:obsidian/core/storage/local_index_service.dart';
import 'package:obsidian/core/storage/local_storage_service.dart';
import 'package:obsidian/core/sync/sync_engine.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

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

class _RemoteItem {
  _RemoteItem({
    required this.path,
    required this.isDir,
    required this.content,
    required this.mTime,
  });

  final String path;
  final bool isDir;
  final String content;
  final DateTime mTime;
}

class _FakeWebDAVService extends WebDAVService {
  final Map<String, _RemoteItem> _items = <String, _RemoteItem>{};
  final List<String> downloaded = <String>[];
  final List<String> uploaded = <String>[];

  void upsertFile(String path, String content, DateTime mTime) {
    final normalized = _normalize(path);
    _ensureDir(_parent(normalized));
    _items[normalized] = _RemoteItem(
      path: normalized,
      isDir: false,
      content: content,
      mTime: mTime,
    );
  }

  void _ensureDir(String path) {
    if (path.isEmpty) {
      return;
    }
    if (_items.containsKey(path)) {
      return;
    }

    final parent = _parent(path);
    if (parent.isNotEmpty) {
      _ensureDir(parent);
    }

    _items[path] = _RemoteItem(
      path: path,
      isDir: true,
      content: '',
      mTime: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<List<webdav.File>> readDir(String path) async {
    final normalized = _normalize(path);
    final parent = normalized == '/' ? '' : normalized;

    final children = _items.values
        .where((item) {
          if (item.path == parent) {
            return false;
          }
          return _parent(item.path) == parent;
        })
        .toList(growable: false);

    return children
        .map((item) {
          return webdav.File(
            path: item.path,
            name: item.path.split('/').last,
            isDir: item.isDir,
            size: item.isDir ? 0 : item.content.length,
            mTime: item.mTime,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> downloadFile(String remotePath, String localFilePath) async {
    final normalized = _normalize(remotePath);
    final item = _items[normalized];
    if (item == null || item.isDir) {
      throw Exception('Remote file not found: $remotePath');
    }

    final file = File(localFilePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(item.content);
    downloaded.add(normalized);
  }

  @override
  Future<void> uploadFile(String remotePath, String localFilePath) async {
    final normalized = _normalize(remotePath);
    uploaded.add(normalized);

    final file = File(localFilePath);
    final content = await file.readAsString();
    _ensureDir(_parent(normalized));
    _items[normalized] = _RemoteItem(
      path: normalized,
      isDir: false,
      content: content,
      mTime: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> mkCol(String path) async {
    _ensureDir(_normalize(path));
  }

  @override
  Future<webdav.File> readProps(String path) async {
    final normalized = _normalize(path);
    final item = _items[normalized];
    if (item == null) {
      throw Exception('Remote props not found: $path');
    }

    return webdav.File(
      path: item.path,
      name: item.path.split('/').last,
      isDir: item.isDir,
      size: item.isDir ? 0 : item.content.length,
      mTime: item.mTime,
    );
  }

  String _normalize(String path) {
    var value = path.trim();
    if (value.isEmpty || value == '/') {
      return '/';
    }
    if (!value.startsWith('/')) {
      value = '/$value';
    }
    if (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  String _parent(String path) {
    if (path == '/' || path.isEmpty) {
      return '';
    }
    final index = path.lastIndexOf('/');
    if (index <= 0) {
      return '';
    }
    return path.substring(0, index);
  }
}

void main() {
  group('SyncEngine', () {
    late Directory tempDir;
    late _FakeLocalStorageService local;
    late LocalIndexService index;
    late _FakeWebDAVService webdav;
    late SyncEngine engine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'vaultclient_sync_engine_test_',
      );
      local = _FakeLocalStorageService(tempDir);
      index = LocalIndexService(local);
      webdav = _FakeWebDAVService();
      engine = SyncEngine(local, index, webdav);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'downloads on first sync and skips unchanged files on second sync',
      () async {
        webdav.upsertFile('/notes/a.md', 'hello', DateTime.utc(2026, 3, 20, 8));

        await engine.syncVault('/');
        expect(webdav.downloaded, equals(<String>['/notes/a.md']));

        webdav.downloaded.clear();
        await engine.syncVault('/');
        expect(webdav.downloaded, isEmpty);
      },
    );

    test('re-downloads when remote metadata changes', () async {
      webdav.upsertFile('/notes/a.md', 'hello', DateTime.utc(2026, 3, 20, 8));
      await engine.syncVault('/');
      webdav.downloaded.clear();

      webdav.upsertFile(
        '/notes/a.md',
        'hello v2',
        DateTime.utc(2026, 3, 20, 9),
      );
      await engine.syncVault('/');

      expect(webdav.downloaded, equals(<String>['/notes/a.md']));
    });

    test('does not upload when remote file metadata matches local', () async {
      final localFile = File('${tempDir.path}/notes/a.md');
      await localFile.parent.create(recursive: true);
      await localFile.writeAsString('hello');

      final localStat = await localFile.stat();
      webdav.upsertFile('/notes/a.md', 'hello', localStat.modified.toUtc());

      await engine.syncVault('/');

      expect(webdav.uploaded, isEmpty);
    });

    test('uploads when local file changed with same size', () async {
      final localFile = File('${tempDir.path}/notes/a.md');
      await localFile.parent.create(recursive: true);

      webdav.upsertFile('/notes/a.md', 'hello', DateTime.utc(2026, 3, 20, 8));
      await localFile.writeAsString('world');
      await localFile.setLastModified(DateTime.utc(2026, 3, 20, 9));

      await engine.syncVault('/');

      expect(webdav.uploaded, contains('/notes/a.md'));
    });

    test('keeps conflict pull actionable on next sync', () async {
      final localFile = File('${tempDir.path}/notes/a.md');
      await localFile.parent.create(recursive: true);
      await localFile.writeAsString('local-change');
      await localFile.setLastModified(DateTime.utc(2026, 3, 20, 10));

      webdav.upsertFile(
        '/notes/a.md',
        'remote-change',
        DateTime.utc(2026, 3, 20, 9),
      );

      await engine.syncVault('/');

      final conflictFile = File('${tempDir.path}/notes/a_remote_conflict.md');
      expect(await conflictFile.exists(), isTrue);

      webdav.downloaded.clear();
      await engine.syncVault('/');

      // 若冲突场景被错误标记为“已同步”，第二次将被跳过。
      expect(webdav.downloaded, contains('/notes/a.md'));
    });

    test(
      'skips malicious remote file names containing traversal characters',
      () async {
        // Upsert a file with a malicious name
        webdav.upsertFile(
          '/notes/../malicious.md',
          'bad content',
          DateTime.utc(2026, 3, 20, 8),
        );
        webdav.upsertFile(
          '/notes/normal.md',
          'good content',
          DateTime.utc(2026, 3, 20, 8),
        );

        final result = await engine.syncVault('/');

        // The malicious file should be skipped, so downloaded is normal.md
        expect(webdav.downloaded, contains('/notes/normal.md'));
        expect(webdav.downloaded, isNot(contains('/notes/../malicious.md')));

        // Because the malicious file was skipped, failedCount should be incremented.
        expect(result.failedCount, greaterThanOrEqualTo(1));
      },
    );
  });
}
