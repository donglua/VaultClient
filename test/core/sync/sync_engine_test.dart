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
    uploaded.add(_normalize(remotePath));
  }

  @override
  Future<void> mkCol(String path) async {
    _ensureDir(_normalize(path));
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
  group('SyncEngine incremental pull', () {
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
  });
}
