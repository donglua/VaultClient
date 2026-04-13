import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main_ui/presentation/providers/file_tree_provider.dart';

/// Obsidian 风格的 Wiki 链接语法解析器，支持 [[link]] 和 ![[image.png]]。
class ObsidianSyntax extends md.InlineSyntax {
  ObsidianSyntax() : super(r'(!)?\\[\\[(.*?)\\]\\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isImage = match.group(1) == '!';
    final content = match.group(2) ?? '';

    // Obsidian 链接支持别名：[[link|alias]]
    final parts = content.split('|');
    final link = parts[0];
    final alias = parts.length > 1 ? parts[1] : link;

    final element = md.Element.text('obsidian_link', alias);
    element.attributes['href'] = link;
    if (isImage) {
      element.attributes['is_image'] = 'true';
    }

    parser.addNode(element);
    return true;
  }
}

/// Obsidian 风格链接的渲染器，支持图片和文件跳转。
class ObsidianLinkBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  final String currentFilePath;
  final WidgetRef ref;

  ObsidianLinkBuilder(this.context, this.currentFilePath, this.ref);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final href = element.attributes['href'] ?? '';
    final isImage = element.attributes['is_image'] == 'true';

    // 相对路径解析
    final currentDir = p.dirname(currentFilePath);

    if (isImage) {
      // 图片：尝试从本地文件加载
      final imagePath = p.normalize(p.join(currentDir, href));
      final imageFile = File(imagePath);

      return FutureBuilder<bool>(
        future: imageFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              imageFile,
              errorBuilder: (context, error, stackTrace) => Text(
                'Error loading image: $href',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          return Text(
            'Image not found: $href',
            style: TextStyle(color: Colors.red),
          );
        },
      );
    } else {
      // 链接到其他 Markdown 文件
      final targetFileName = href.endsWith('.md') ? href : '$href.md';
      final targetPath = p.normalize(p.join(currentDir, targetFileName));
      final targetFile = File(targetPath);

      return GestureDetector(
        onTap: () async {
          if (await targetFile.exists()) {
            // 通过 Riverpod 更新选中文件
            ref.read(selectedFileProvider.notifier).selectFile(targetFile);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File not found: $targetPath')),
              );
            }
          }
        },
        child: Text(
          element.textContent,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
  }
}
