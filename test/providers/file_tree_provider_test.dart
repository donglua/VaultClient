import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/features/main_ui/presentation/providers/file_tree_provider.dart';

void main() {
  group('FileTreeNotifier.normalizeRelativePath', () {
    test('should normalize basic paths', () {
      expect(FileTreeNotifier.normalizeRelativePath('a/b/c'), 'a/b/c');
    });

    test('should trim leading and trailing whitespace', () {
      expect(FileTreeNotifier.normalizeRelativePath('  a/b/c  '), 'a/b/c');
    });

    test('should remove leading slashes', () {
      expect(FileTreeNotifier.normalizeRelativePath('/a/b/c'), 'a/b/c');
      expect(FileTreeNotifier.normalizeRelativePath('///a/b/c'), 'a/b/c');
    });

    test('should handle trailing slashes', () {
      // p.posix.normalize('a/b/c/') typically returns 'a/b/c'
      expect(FileTreeNotifier.normalizeRelativePath('a/b/c/'), 'a/b/c');
    });

    test('should handle internal redundant slashes', () {
      expect(FileTreeNotifier.normalizeRelativePath('a///b'), 'a/b');
    });

    test('should handle redundant path segments', () {
      expect(FileTreeNotifier.normalizeRelativePath('a/./b'), 'a/b');
      expect(FileTreeNotifier.normalizeRelativePath('a/b/../c'), 'a/c');
    });

    test('should return empty string for empty or dot-only inputs', () {
      expect(FileTreeNotifier.normalizeRelativePath(''), '');
      expect(FileTreeNotifier.normalizeRelativePath('.'), '');
      expect(FileTreeNotifier.normalizeRelativePath('  '), '');
      expect(FileTreeNotifier.normalizeRelativePath('./'), '');
    });

    test('should return empty string for root slashes', () {
      expect(FileTreeNotifier.normalizeRelativePath('/'), '');
      expect(FileTreeNotifier.normalizeRelativePath('//'), '');
    });

    test('should handle complex cases', () {
      expect(
        FileTreeNotifier.normalizeRelativePath('  /./a//b/../c/  '),
        'a/c',
      );
    });
  });
}
