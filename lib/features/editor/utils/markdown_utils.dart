import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main_ui/providers/file_tree_provider.dart';

class ObsidianSyntax extends md.InlineSyntax {
  // Matches [[link]] and ![[image.png]]
  ObsidianSyntax() : super(r'(!)?\[\[(.*?)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isImage = match.group(1) == '!';
    final content = match.group(2) ?? '';

    // In Obsidian, links can have aliases: [[link|alias]]
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

class ObsidianLinkBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  final String currentFilePath;
  final WidgetRef ref;

  ObsidianLinkBuilder(this.context, this.currentFilePath, this.ref);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final href = element.attributes['href'] ?? '';
    final isImage = element.attributes['is_image'] == 'true';

    // Resolve relative path strictly as requested
    final currentDir = p.dirname(currentFilePath);

    if (isImage) {
      // It's an image. Try to load from local file.
      final imagePath = p.normalize(p.join(currentDir, href));
      final imageFile = File(imagePath);

      return FutureBuilder<bool>(
        future: imageFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(imageFile, errorBuilder: (context, error, stackTrace) => Text('Error loading image: $href', style: TextStyle(color: Colors.red)));
          }
          return Text('Image not found: $href', style: TextStyle(color: Colors.red));
        },
      );
    } else {
      // It's a link to another markdown file.
      // Append .md if not present to match file system
      final targetFileName = href.endsWith('.md') ? href : '$href.md';
      final targetPath = p.normalize(p.join(currentDir, targetFileName));
      final targetFile = File(targetPath);

      return GestureDetector(
        onTap: () async {
          if (await targetFile.exists()) {
             // Change selected file in Riverpod
             ref.read(selectedFileProvider.notifier).selectFile(targetFile);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File not found: $targetPath')));
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
