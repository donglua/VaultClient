import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/storage/local_storage_service.dart';
import 'package:path/path.dart' as p;

class _TestLocalStorageService extends LocalStorageService {
  final Directory _vaultDir;
  _TestLocalStorageService(this._vaultDir);

  @override
  Future<Directory> getVaultDirectory() async => _vaultDir;
}

void main() {
  group('LocalStorageService Path Traversal', () {
    late Directory tempDir;
    late Directory vaultDir;
    late _TestLocalStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lss_test_');
      vaultDir = Directory(p.join(tempDir.path, 'vault'));
      await vaultDir.create();
      service = _TestLocalStorageService(vaultDir);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('listFiles should throw ArgumentError when escaping vault directory via ..', () async {
      final secretDir = Directory(p.join(tempDir.path, 'secret'));
      await secretDir.create();
      await File(p.join(secretDir.path, 'passwords.txt')).writeAsString('secret');

      expect(
        () => service.listFiles('../secret'),
        throwsArgumentError,
      );
    });

    test('getFile should throw ArgumentError when escaping vault directory via absolute path', () async {
      final secretFile = File(p.join(tempDir.path, 'secret.txt'));
      await secretFile.writeAsString('sensitive data');

      expect(
        () => service.getFile(secretFile.path),
        throwsArgumentError,
      );
    });

    test('getFile should allow access to files within vault', () async {
      final noteFile = File(p.join(vaultDir.path, 'note.md'));
      await noteFile.writeAsString('hello');

      final file = await service.getFile('note.md');
      expect(p.canonicalize(file.path), p.canonicalize(noteFile.path));
    });
   group('Validated Path Logic', () {
      test('should allow valid relative paths', () async {
        final file = await service.getFile('folder/note.md');
        expect(file.path.endsWith('folder/note.md'), isTrue);
      });

      test('should allow path equal to vault', () async {
        final dir = await service.listFiles('.');
        expect(dir, isNotNull);
      });

      test('should block directory traversal even if path exists', () async {
        // Handled by generic traversal test above, but good to be explicit
        expect(() => service.getFile('folder/../../secret.txt'), throwsArgumentError);
      });
    });
  });
}
