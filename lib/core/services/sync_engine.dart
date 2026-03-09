import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';
import 'webdav_service.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final webdavServiceProvider = Provider<WebDAVService>((ref) {
  return WebDAVService();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  final webdav = ref.watch(webdavServiceProvider);
  return SyncEngine(local, webdav);
});

/// Core engine responsible for bidirectional synchronization
/// between the local file system (LocalStorageService) and a remote
/// WebDAV server (WebDAVService).
class SyncEngine {
  final LocalStorageService _local;
  final WebDAVService _webdav;

  SyncEngine(this._local, this._webdav);

  /// Initiates a full synchronization of the vault.
  ///
  /// The synchronization strategy is "Pull then Push":
  /// 1. It recursively traverses the remote directory.
  /// 2. It compares remote file metadata (mTime, size) against local metadata.
  /// 3. If there is a conflict (local file modified but differs from remote),
  ///    it keeps both versions by downloading the remote as `_remote_conflict`.
  /// 4. It then pushes local files that are missing or newer on the remote server.
  ///
  /// [remoteBasePath] The base path on the WebDAV server to sync with.
  Future<void> syncVault(String remoteBasePath) async {
    final vaultDir = await _local.getVaultDirectory();
    await _pullRemote(remoteBasePath, '', vaultDir.path);
    await _pushLocal(vaultDir.path, '', remoteBasePath);
  }

  /// Helper method to recursively pull files from the remote WebDAV server to local storage.
  ///
  /// [remoteBasePath] The root directory on the server.
  /// [relativePath] The current sub-directory being processed.
  /// [localVaultPath] The absolute path to the local vault on the device.
  Future<void> _pullRemote(String remoteBasePath, String relativePath, String localVaultPath) async {
    try {
      final remoteFiles = await _webdav.readDir(p.join(remoteBasePath, relativePath));
      for (var file in remoteFiles) {
        if (file.name == null || file.name!.isEmpty) continue;

        final remoteItemPath = file.path!;
        final localItemRelPath = p.join(relativePath, file.name!);
        final localItemFullPath = p.join(localVaultPath, localItemRelPath);

        if (file.isDir == true) {
          final localDir = Directory(localItemFullPath);
          if (!await localDir.exists()) {
            await localDir.create(recursive: true);
          }
          await _pullRemote(remoteBasePath, localItemRelPath, localVaultPath);
        } else {
          final localFile = File(localItemFullPath);
          bool shouldDownload = true;
          bool isConflict = false;

          if (await localFile.exists()) {
            final stat = await localFile.stat();
            if (file.mTime != null) {
              // If local and remote have same size and close modification time, skip
              if (file.size == stat.size && (stat.modified.difference(file.mTime!).inSeconds).abs() < 2) {
                 shouldDownload = false;
              } else if (stat.modified.isAfter(file.mTime!)) {
                 // Local is newer. We have a conflict.
                 // The user wants to keep BOTH versions.
                 // We download the remote as `_remote_conflict` and keep our local file intact.
                 isConflict = true;
                 shouldDownload = true;
              } else {
                 // Remote is newer, just download and overwrite local
                 shouldDownload = true;
              }
            }
          }

          if (shouldDownload) {
            if (isConflict) {
               final ext = p.extension(localItemFullPath);
               final baseName = p.basenameWithoutExtension(localItemFullPath);
               final conflictPath = p.join(p.dirname(localItemFullPath), '${baseName}_remote_conflict$ext');
               await _webdav.downloadFile(remoteItemPath, conflictPath);
            } else {
               await _webdav.downloadFile(remoteItemPath, localItemFullPath);
               // Try to sync modification times to avoid re-downloading if sizes match.
               // Dart's File API doesn't allow setting mtime directly, so subsequent syncs rely heavily on size check.
            }
          }
        }
      }
    } catch (e) {
      print('Pull remote failed for $relativePath: $e');
    }
  }

  /// Helper method to recursively push files from the local storage to the remote WebDAV server.
  ///
  /// [localVaultPath] The absolute path to the local vault on the device.
  /// [relativePath] The current sub-directory being processed.
  /// [remoteBasePath] The root directory on the server.
  Future<void> _pushLocal(String localVaultPath, String relativePath, String remoteBasePath) async {
    final localDir = Directory(p.join(localVaultPath, relativePath));
    if (!await localDir.exists()) return;

    final entities = localDir.listSync(recursive: false);
    for (var entity in entities) {
      final name = p.basename(entity.path);

      // Do not push conflict files back to the server.
      // We expect the user to manually resolve them and delete the conflict file.
      if (name.contains('_remote_conflict')) continue;

      final remoteItemPath = p.join(remoteBasePath, relativePath, name);

      if (entity is Directory) {
        await _webdav.mkCol(remoteItemPath);
        await _pushLocal(localVaultPath, p.join(relativePath, name), remoteBasePath);
      } else if (entity is File) {
        try {
          final remoteStat = await _webdav.readDir(remoteItemPath).catchError((_) => <webdav.File>[]);
          bool shouldUpload = false;

          if (remoteStat.isEmpty) {
            shouldUpload = true; // Does not exist on remote
          } else {
            final stat = await entity.stat();
            final remoteFile = remoteStat.first;

            if (remoteFile.mTime != null) {
              // Only upload if local is newer and sizes differ
              if (stat.modified.isAfter(remoteFile.mTime!) && stat.size != remoteFile.size) {
                shouldUpload = true;
              }
            } else {
              shouldUpload = true;
            }
          }

          if (shouldUpload) {
            await _webdav.uploadFile(remoteItemPath, entity.path);
          }
        } catch (e) {
          // If error occurs reading remote, assume it doesn't exist and upload
          await _webdav.uploadFile(remoteItemPath, entity.path);
        }
      }
    }
  }
}
