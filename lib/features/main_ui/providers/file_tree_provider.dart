import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sync_engine.dart';

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

  /// 刷新文件树
  /// 
  /// 调用此方法会在同步完成后更新文件树显示
  Future<void> refresh() async {
    try {
      final local = ref.read(localStorageServiceProvider);
      final files = await local.listFiles('');
      state = files;
    } catch (e) {
      print('[FileTreeNotifier] Failed to refresh: $e');
      state = [];
    }
  }
}

final fileTreeNotifierProvider = NotifierProvider<FileTreeNotifier, List<FileSystemEntity>>(() {
  return FileTreeNotifier();
});
