import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:obsidian/l10n/app_localizations.dart';
import '../utils/markdown_utils.dart';

/// 支持 Obsidian 扩展语法（WikiLinks）的 Markdown 编辑器和预览页面。
class EditorScreen extends ConsumerStatefulWidget {
  final File file;
  final bool isDesktop;

  const EditorScreen({super.key, required this.file, this.isDesktop = false});

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _controller;
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (await widget.file.exists()) {
      final content = await widget.file.readAsString();
      if (!mounted) {
        return;
      }
      setState(() {
        _controller.text = content;
      });
    }
  }

  @override
  void didUpdateWidget(covariant EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _loadFile();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: widget.isDesktop ? null : AppBar(title: Text(widget.file.path.split('/').last)),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: _insertImage,
                    tooltip: l10n.insertImage,
                  ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  tooltip: _isEditing ? l10n.preview : l10n.edit,
                ),
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    await widget.file.writeAsString(_controller.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.savedLocally)));
                    }
                  },
                  tooltip: l10n.save,
                )
              ],
            ),
          ),
          Expanded(
            child: _isEditing ? _buildEditor() : _buildPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        decoration: InputDecoration.collapsed(hintText: AppLocalizations.of(context)!.writeMarkdownHere),
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Markdown(
        data: _controller.text,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: [ObsidianSyntax()],
        builders: {
          'obsidian_link': ObsidianLinkBuilder(context, widget.file.path, ref),
        },
      ),
    );
  }

  /// 从本地文件系统选择图片，复制到 vault 并在编辑器中插入对应的 Markdown 语法。
  Future<void> _insertImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      File pickedImage = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // 将图片保存到当前文件所在目录
      final currentDir = p.dirname(widget.file.path);
      final newImagePath = p.join(currentDir, fileName);

      await pickedImage.copy(newImagePath);

      // 插入 Markdown 语法到编辑器
      final text = _controller.text;
      final selection = _controller.selection;

      final insertText = "![[$fileName]]\n";

      if (selection.start >= 0 && selection.end >= 0) {
        final newText = text.replaceRange(selection.start, selection.end, insertText);
        _controller.value = _controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + insertText.length),
        );
      } else {
        _controller.text = text + insertText;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.imageInserted)));
      }
    }
  }
}
