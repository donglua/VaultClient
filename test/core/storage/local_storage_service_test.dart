import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/storage/local_storage_service.dart';
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
  group('LocalStorageService', () {
    late Directory tempDir;
    late LocalStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'obsidian_storage_test_',
      );
      service = _FakeLocalStorageService(tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writeFile and readFile happy path', () async {
      const relativePath = 'test.md';
      const content = 'hello world';

      await service.writeFile(relativePath, content);
      final readContent = await service.readFile(relativePath);

      expect(readContent, content);
    });

    test('writeFile creates parent directories', () async {
      const relativePath = 'nested/dir/test.md';
      const content = 'nested content';

      await service.writeFile(relativePath, content);
      final file = File(p.join(tempDir.path, relativePath));

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), content);
    });

    test('readFile throws Exception when file does not exist', () async {
      const relativePath = 'non_existent.md';

      expect(
        () => service.readFile(relativePath),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', 'Exception: File not found')),
      );
    });

    test('writeBinaryFile and reading it back', () async {
      const relativePath = 'test.bin';
      final bytes = [0, 1, 2, 3, 4, 5];

      await service.writeBinaryFile(relativePath, bytes);
      final file = File(p.join(tempDir.path, relativePath));

      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('deleteFile deletes existing file', () async {
      const relativePath = 'to_delete.md';
      await service.writeFile(relativePath, 'content');

      await service.deleteFile(relativePath);
      final file = File(p.join(tempDir.path, relativePath));

      expect(await file.exists(), isFalse);
    });

    test('deleteFile does nothing when file does not exist', () async {
      const relativePath = 'never_existed.md';

      await service.deleteFile(relativePath);
      // Should not throw
    });

    test('listFiles lists files in directory', () async {
      await service.writeFile('a.md', 'a');
      await service.writeFile('sub/b.md', 'b');

      final rootFiles = await service.listFiles('');
      // In Dart, Directory.list returns both files and directories.
      // rootDir contains 'a.md' and 'sub' directory.
      expect(rootFiles.length, 2);

      final subFiles = await service.listFiles('sub');
      expect(subFiles.length, 1);
      expect(p.basename(subFiles.first.path), 'b.md');
    });

    test('listFiles returns empty list for non-existent directory', () async {
      final files = await service.listFiles('ghost');
      expect(files, isEmpty);
    });
  });
}
