import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 本地文件存储服务，封装对应用文档目录下 vault 文件夹的读写操作。
class LocalStorageService {
  Future<Directory>? _vaultDirectoryFuture;

  Future<Directory> getVaultDirectory() {
    return _vaultDirectoryFuture ??= _initializeVaultDirectory();
  }

  Future<Directory> _initializeVaultDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDocDir.path}/vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<File> getFile(String relativePath) async {
    final vaultDir = await getVaultDirectory();
    return File(p.join(vaultDir.path, relativePath));
  }

  Future<void> writeFile(String relativePath, String content) async {
    final file = await getFile(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> writeBinaryFile(String relativePath, List<int> bytes) async {
    final file = await getFile(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<String> readFile(String relativePath) async {
    final file = await getFile(relativePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('File not found');
  }

  Future<void> deleteFile(String relativePath) async {
    final file = await getFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<FileSystemEntity>> listFiles(String relativePath) async {
    final vaultDir = await getVaultDirectory();
    final targetDir = Directory(p.join(vaultDir.path, relativePath));
    if (await targetDir.exists()) {
      return await targetDir.list(recursive: false).toList();
    }
    return [];
  }
}
