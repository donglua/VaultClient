import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';
import '../network/webdav_service.dart';
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

/// 核心同步引擎，负责本地文件系统（LocalStorageService）与
/// 远程 WebDAV 服务器（WebDAVService）之间的双向同步。
class SyncEngine {
  final LocalStorageService _local;
  final WebDAVService _webdav;

  SyncEngine(this._local, this._webdav);

  /// 发起完整的 Vault 同步。
  ///
  /// 同步策略为"先拉取、后推送"：
  /// 1. 递归遍历远程目录。
  /// 2. 对比远程文件元数据（mTime、size）与本地文件。
  /// 3. 如果有冲突（本地文件较新且与远程不同），则将远程版本下载为 `_remote_conflict`。
  /// 4. 再将本地缺少或更新的文件推送到远程服务器。
  ///
  /// [remoteBasePath] 要同步的 WebDAV 服务器根路径。
  Future<void> syncVault(String remoteBasePath) async {
    final vaultDir = await _local.getVaultDirectory();
    await _pullRemote(remoteBasePath, '', vaultDir.path);
    await _pushLocal(vaultDir.path, '', remoteBasePath);
  }

  /// 递归地将远程 WebDAV 服务器文件拉取到本地存储。
  ///
  /// [remoteBasePath] 服务器根目录。
  /// [relativePath] 当前处理的子目录。
  /// [localVaultPath] 本地 vault 的绝对路径。
  Future<void> _pullRemote(String remoteBasePath, String relativePath, String localVaultPath) async {
    try {
      String remotePath;
      if (relativePath.isEmpty) {
        remotePath = remoteBasePath.isEmpty ? '/' : remoteBasePath;
      } else {
        final base = remoteBasePath.isEmpty ? '' : (remoteBasePath.endsWith('/') ? remoteBasePath.substring(0, remoteBasePath.length - 1) : remoteBasePath);
        remotePath = '$base/$relativePath';
      }
      
      final remoteFiles = await _webdav.readDir(remotePath);
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
              if (file.size == stat.size && (stat.modified.difference(file.mTime!).inSeconds).abs() < 2) {
                 shouldDownload = false;
              } else if (stat.modified.isAfter(file.mTime!)) {
                 // 本地文件更新，产生冲突，保留两个版本
                 isConflict = true;
                 shouldDownload = true;
              } else {
                 // 远程文件更新，下载覆盖本地
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
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Pull remote failed for $relativePath: $e');
    }
  }

  /// 递归地将本地存储文件推送到远程 WebDAV 服务器。
  ///
  /// [localVaultPath] 本地 vault 的绝对路径。
  /// [relativePath] 当前处理的子目录。
  /// [remoteBasePath] 服务器根目录。
  Future<void> _pushLocal(String localVaultPath, String relativePath, String remoteBasePath) async {
    final localDir = Directory(p.join(localVaultPath, relativePath));
    if (!await localDir.exists()) return;

    final entities = localDir.listSync(recursive: false);
    for (var entity in entities) {
      final name = p.basename(entity.path);

      // 冲突文件不推送回服务器，需要用户手动处理后删除
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
            shouldUpload = true; // 远程不存在该文件
          } else {
            final stat = await entity.stat();
            final remoteFile = remoteStat.first;

            if (remoteFile.mTime != null) {
              // 仅当本地更新且大小不同时才上传
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
          // 读取远程出错时，假设不存在并上传
          await _webdav.uploadFile(remoteItemPath, entity.path);
        }
      }
    }
  }
}
