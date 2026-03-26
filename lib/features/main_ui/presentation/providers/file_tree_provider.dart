import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/sync/sync_engine.dart';

final selectedFileProvider = NotifierProvider<SelectedFileNotifier, File?>(() {
  return SelectedFileNotifier();
});

class SelectedFileNotifier extends Notifier<File?> {
  @override
  File? build() {
    return null;
  }

  void selectFile(File file) {
    state = file;
  }
}

class FileTreeNotifier extends Notifier<List<FileSystemEntity>> {
  @override
  List<FileSystemEntity> build() {
    // 初始构建时不立即刷新，避免在 build 中触发异步操作
    return [];
  }

  /// 刷新文件树。
  ///
  /// 优先根据本地索引构建顶层目录，保证断网时仍能展示最近同步结果。
  /// 如果索引缺失或为空，则回退到直接扫描本地目录。
  Future<void> refresh() async {
    try {
      final local = ref.read(localStorageServiceProvider);
      final fromIndex = await _buildFromIndex();
      if (fromIndex.isNotEmpty) {
        state = fromIndex;
        return;
      }

      final files = await local.listFiles('');
      state = _sortEntities(files);
    } catch (e) {
      debugPrint('[FileTreeNotifier] Failed to refresh: $e');
      state = [];
    }
  }

  Future<List<FileSystemEntity>> _buildFromIndex() async {
    final local = ref.read(localStorageServiceProvider);
    final index = ref.read(localIndexServiceProvider);
    final entries = await index.loadEntries();
    if (entries.isEmpty) {
      return [];
    }

    final vaultDir = await local.getVaultDirectory();
    final topLevel = <String, FileSystemEntity>{};

    for (final entry in entries) {
      final normalized = FileTreeNotifier.normalizeRelativePath(entry.relativePath);
      if (normalized.isEmpty) {
        continue;
      }

      final firstSegment = normalized.split('/').first;
      if (firstSegment.isEmpty || firstSegment.startsWith('.')) {
        continue;
      }

      final targetPath = p.join(vaultDir.path, firstSegment);
      final shouldBeDir = entry.isDir || normalized.contains('/');

      final existing = topLevel[firstSegment];
      if (existing is Directory) {
        continue;
      }

      topLevel[firstSegment] = shouldBeDir
          ? Directory(targetPath)
          : File(targetPath);
    }

    return _sortEntities(topLevel.values.toList(growable: false));
  }

  @visibleForTesting
  static String normalizeRelativePath(String value) {
    var normalized = p.posix.normalize(value.trim());
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    if (normalized == '.') {
      return '';
    }
    return normalized;
  }

  List<FileSystemEntity> _sortEntities(List<FileSystemEntity> entities) {
    final sorted = List<FileSystemEntity>.from(entities);
    sorted.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) {
        return -1;
      }
      if (!aIsDir && bIsDir) {
        return 1;
      }
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
    return sorted;
  }
}

final fileTreeNotifierProvider =
    NotifierProvider<FileTreeNotifier, List<FileSystemEntity>>(() {
      return FileTreeNotifier();
    });
