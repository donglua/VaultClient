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
    refresh();
    return [];
  }

  Future<void> refresh() async {
    final local = ref.read(localStorageServiceProvider);
    state = await local.listFiles('');
  }
}

final fileTreeNotifierProvider = NotifierProvider<FileTreeNotifier, List<FileSystemEntity>>(() {
  return FileTreeNotifier();
});
