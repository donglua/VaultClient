import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../network/webdav_service.dart';
import '../storage/local_index_service.dart';
import '../storage/local_storage_service.dart';
import 'models/sync_entry.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final webdavServiceProvider = Provider<WebDAVService>((ref) {
  return WebDAVService();
});

final localIndexServiceProvider = Provider<LocalIndexService>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  return LocalIndexService(local);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  final index = ref.watch(localIndexServiceProvider);
  final webdav = ref.watch(webdavServiceProvider);
  return SyncEngine(local, index, webdav);
});

/// 核心同步引擎，负责本地文件系统（LocalStorageService）与
/// 远程 WebDAV 服务器（WebDAVService）之间的双向同步。
class SyncEngine {
  static const String _indexFileName = '.vault_index.json';

  final LocalStorageService _local;
  final LocalIndexService _index;
  final WebDAVService _webdav;

  SyncEngine(this._local, this._index, this._webdav);

  /// 发起完整的 Vault 同步。
  ///
  /// 同步策略为"先拉取、后推送"：
  /// 1. 递归遍历远程目录。
  /// 2. 对比远程文件元数据（mTime、size）与索引缓存。
  /// 3. 仅在远程有变化时下载，减少无效流量。
  /// 4. 再将本地缺少或更新的文件推送到远程服务器。
  ///
  /// [remoteBasePath] 要同步的 WebDAV 服务器根路径。
  Future<SyncResult> syncVault(String remoteBasePath) async {
    final stopwatch = Stopwatch()..start();
    final stats = _SyncStats();

    final basePath = _normalizeRemoteBasePath(remoteBasePath);
    final vaultDir = await _local.getVaultDirectory();
    final indexMap = await _index.loadEntryMap();

    await _pullRemote(basePath, '', vaultDir.path, indexMap, stats);
    await _index.bulkReplace(indexMap.values);

    await _pushLocal(vaultDir.path, '', basePath, stats);

    stopwatch.stop();
    return SyncResult(
      scannedCount: stats.scannedCount,
      downloadedCount: stats.downloadedCount,
      skippedCount: stats.skippedCount,
      failedCount: stats.failedCount,
      elapsed: stopwatch.elapsed,
    );
  }

  /// 递归地将远程 WebDAV 服务器文件拉取到本地存储。
  ///
  /// [remoteBasePath] 服务器根目录。
  /// [relativePath] 当前处理的子目录。
  /// [localVaultPath] 本地 vault 的绝对路径。
  Future<void> _pullRemote(
    String remoteBasePath,
    String relativePath,
    String localVaultPath,
    Map<String, SyncEntry> indexMap,
    _SyncStats stats,
  ) async {
    final remotePath = _resolveRemotePath(remoteBasePath, relativePath);

    try {
      final remoteFiles = await _webdav.readDir(remotePath);
      for (final file in remoteFiles) {
        if (file.name == null || file.name!.isEmpty) {
          continue;
        }

        if (file.name == _indexFileName) {
          continue;
        }

        stats.scannedCount++;

        final localItemRelPath = relativePath.isEmpty
            ? file.name!
            : p.posix.join(relativePath, file.name!);
        final localItemFullPath = p.joinAll([
          localVaultPath,
          ...p.posix.split(localItemRelPath),
        ]);

        if (file.isDir == true) {
          final localDir = Directory(localItemFullPath);
          if (!await localDir.exists()) {
            await localDir.create(recursive: true);
          }

          final localDirStat = await localDir.stat();
          indexMap[localItemRelPath] = SyncEntry(
            relativePath: localItemRelPath,
            isDir: true,
            size: 0,
            remoteMTimeMillis: file.mTime?.millisecondsSinceEpoch,
            localMTimeMillis: localDirStat.modified.millisecondsSinceEpoch,
            etag: null,
            lastSyncedAtMillis: DateTime.now().millisecondsSinceEpoch,
          );

          await _pullRemote(
            remoteBasePath,
            localItemRelPath,
            localVaultPath,
            indexMap,
            stats,
          );
          continue;
        }

        final localFile = File(localItemFullPath);
        final oldEntry = indexMap[localItemRelPath];
        final decision = await _decidePull(file, localFile, oldEntry);

        if (decision.shouldDownload) {
          final remoteItemPath =
              file.path ?? p.posix.join(remotePath, file.name!);

          if (decision.isConflictDownload) {
            final ext = p.extension(localItemFullPath);
            final baseName = p.basenameWithoutExtension(localItemFullPath);
            final conflictPath = p.join(
              p.dirname(localItemFullPath),
              '${baseName}_remote_conflict$ext',
            );
            await _webdav.downloadFile(remoteItemPath, conflictPath);
          } else {
            await _webdav.downloadFile(remoteItemPath, localItemFullPath);
          }
          stats.downloadedCount++;
        } else {
          stats.skippedCount++;
        }

        // 冲突文件仅作为旁路副本下载，不应把原文件标记为“已与远端一致”。
        if (decision.isConflictDownload) {
          continue;
        }

        final localStat = await localFile.exists()
            ? await localFile.stat()
            : null;
        indexMap[localItemRelPath] = SyncEntry(
          relativePath: localItemRelPath,
          isDir: false,
          size: file.size ?? 0,
          remoteMTimeMillis: file.mTime?.millisecondsSinceEpoch,
          localMTimeMillis: localStat?.modified.millisecondsSinceEpoch,
          etag: null,
          lastSyncedAtMillis: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      stats.failedCount++;
      if (kDebugMode) {
        debugPrint('Pull remote failed for $relativePath: $e');
      }
    }
  }

  /// 递归地将本地存储文件推送到远程 WebDAV 服务器。
  ///
  /// [localVaultPath] 本地 vault 的绝对路径。
  /// [relativePath] 当前处理的子目录。
  /// [remoteBasePath] 服务器根目录。
  Future<void> _pushLocal(
    String localVaultPath,
    String relativePath,
    String remoteBasePath,
    _SyncStats stats,
  ) async {
    final localDir = Directory(
      p.joinAll([localVaultPath, ...p.posix.split(relativePath)]),
    );
    if (!await localDir.exists()) {
      return;
    }

    final entities = localDir.listSync(recursive: false);
    for (final entity in entities) {
      final name = p.basename(entity.path);

      // 索引文件是本地内部实现细节，不应同步到远程。
      if (relativePath.isEmpty && name == _indexFileName) {
        continue;
      }

      // 冲突文件不推送回服务器，需要用户手动处理后删除。
      if (name.contains('_remote_conflict')) {
        continue;
      }

      final remoteItemPath = relativePath.isEmpty
          ? p.posix.join(remoteBasePath, name)
          : p.posix.join(remoteBasePath, relativePath, name);

      if (entity is Directory) {
        await _webdav.mkCol(remoteItemPath);
        final childRelativePath = relativePath.isEmpty
            ? name
            : p.posix.join(relativePath, name);
        await _pushLocal(
          localVaultPath,
          childRelativePath,
          remoteBasePath,
          stats,
        );
      } else if (entity is File) {
        try {
          final remoteFile = await _webdav.readProps(remoteItemPath);
          bool shouldUpload = false;

          final stat = await entity.stat();
          if (remoteFile.mTime != null) {
            // 本地更新后，只要大小或 mtime 任一不一致，就上传覆盖。
            final sizeDiffers = stat.size != (remoteFile.size ?? 0);
            final mTimeDiffers =
                stat.modified.difference(remoteFile.mTime!).inSeconds.abs() >= 2;
            if (stat.modified.isAfter(remoteFile.mTime!) &&
                (sizeDiffers || mTimeDiffers)) {
              shouldUpload = true;
            }
          } else {
            shouldUpload = true;
          }

          if (shouldUpload) {
            await _webdav.uploadFile(remoteItemPath, entity.path);
          }
        } catch (_) {
          stats.failedCount++;
          // 读取远程出错时，假设不存在并上传
          try {
            await _webdav.uploadFile(remoteItemPath, entity.path);
          } catch (_) {
            stats.failedCount++;
          }
        }
      }
    }
  }

  Future<_PullDecision> _decidePull(
    webdav.File remoteFile,
    File localFile,
    SyncEntry? oldEntry,
  ) async {
    final exists = await localFile.exists();
    if (!exists) {
      return const _PullDecision(
        shouldDownload: true,
        isConflictDownload: false,
      );
    }

    if (oldEntry != null && _sameRemoteMetadata(remoteFile, oldEntry)) {
      return const _PullDecision(
        shouldDownload: false,
        isConflictDownload: false,
      );
    }

    final stat = await localFile.stat();
    if (remoteFile.mTime == null) {
      final shouldDownload = remoteFile.size != stat.size;
      return _PullDecision(
        shouldDownload: shouldDownload,
        isConflictDownload: false,
      );
    }

    final almostSameTime =
        (stat.modified.difference(remoteFile.mTime!).inSeconds).abs() < 2;
    if (remoteFile.size == stat.size && almostSameTime) {
      return const _PullDecision(
        shouldDownload: false,
        isConflictDownload: false,
      );
    }

    if (stat.modified.isAfter(remoteFile.mTime!)) {
      return const _PullDecision(
        shouldDownload: true,
        isConflictDownload: true,
      );
    }

    return const _PullDecision(shouldDownload: true, isConflictDownload: false);
  }

  bool _sameRemoteMetadata(webdav.File remoteFile, SyncEntry oldEntry) {
    return oldEntry.remoteMTimeMillis ==
            remoteFile.mTime?.millisecondsSinceEpoch &&
        oldEntry.size == remoteFile.size;
  }

  String _normalizeRemoteBasePath(String remoteBasePath) {
    final trimmed = remoteBasePath.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return '/';
    }

    final withLeadingSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (withLeadingSlash.length > 1 && withLeadingSlash.endsWith('/')) {
      return withLeadingSlash.substring(0, withLeadingSlash.length - 1);
    }

    return withLeadingSlash;
  }

  String _resolveRemotePath(String remoteBasePath, String relativePath) {
    if (relativePath.isEmpty) {
      return remoteBasePath;
    }

    if (remoteBasePath == '/') {
      return '/$relativePath';
    }

    return '$remoteBasePath/$relativePath';
  }
}

class _PullDecision {
  final bool shouldDownload;
  final bool isConflictDownload;

  const _PullDecision({
    required this.shouldDownload,
    required this.isConflictDownload,
  });
}

class SyncResult {
  final int scannedCount;
  final int downloadedCount;
  final int skippedCount;
  final int failedCount;
  final Duration elapsed;

  const SyncResult({
    required this.scannedCount,
    required this.downloadedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.elapsed,
  });
}

class _SyncStats {
  int scannedCount = 0;
  int downloadedCount = 0;
  int skippedCount = 0;
  int failedCount = 0;
}
