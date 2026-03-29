import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:obsidian/l10n/app_localizations.dart';
import '../utils/markdown_utils.dart';
import '../../../../main.dart';

/// 支持 Obsidian 扩展语法（WikiLinks）的 Markdown 编辑器和预览页面。
class EditorScreen extends ConsumerStatefulWidget {
  final File file;
  final bool isDesktop;

  const EditorScreen({super.key, required this.file, this.isDesktop = false});

  @override
  // ignore: library_private_types_in_public_api
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _controller;
  bool _isEditing = true;
  bool _isSaving = false;
  bool _isDetailPanelOpen = true; // 桌面端右侧详情面板

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (await widget.file.exists()) {
      final content = await widget.file.readAsString();
      if (!mounted) return;
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

  Future<void> _saveFile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.file.writeAsString(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.savedLocally,
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 统计字数
  int get _wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  /// 估算阅读时间（分钟，按200字/分钟）
  int get _readingMinutes => (_wordCount / 200).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (widget.isDesktop) {
      return _buildDesktopLayout(isDark, l10n);
    }
    return _buildMobileLayout(isDark, l10n);
  }

  // ─────────────────────────── 桌面布局 ───────────────────────────

  Widget _buildDesktopLayout(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        // 顶部工具栏
        _DesktopEditorTopBar(
          isDark: isDark,
          file: widget.file,
          isEditing: _isEditing,
          isDetailOpen: _isDetailPanelOpen,
          isSaving: _isSaving,
          onToggleMode: () => setState(() => _isEditing = !_isEditing),
          onToggleDetail: () =>
              setState(() => _isDetailPanelOpen = !_isDetailPanelOpen),
          onSave: _saveFile,
          l10n: l10n,
        ),
        // Markdown 格式化工具栏（仅编辑模式）
        if (_isEditing)
          _MarkdownToolbar(
            isDark: isDark,
            controller: _controller,
            onInsertImage: _insertImage,
          ),
        // 内容区（编辑器 + 右侧详情面板）
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 编辑/预览区
              Expanded(
                child: _isEditing
                    ? _buildEditor(isDark)
                    : _buildPreview(isDark),
              ),
              // 右侧文档详情（桌面端）
              if (_isDetailPanelOpen)
                _DocumentDetailPanel(
                  isDark: isDark,
                  file: widget.file,
                  wordCount: _wordCount,
                  readingMinutes: _readingMinutes,
                  onSave: _saveFile,
                  isSaving: _isSaving,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── 移动布局 ───────────────────────────

  Widget _buildMobileLayout(bool isDark, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          _MobileEditorTopBar(
            isDark: isDark,
            file: widget.file,
            isEditing: _isEditing,
            isSaving: _isSaving,
            onToggleMode: () => setState(() => _isEditing = !_isEditing),
            onSave: _saveFile,
            l10n: l10n,
          ),
          if (_isEditing)
            _MarkdownToolbar(
              isDark: isDark,
              controller: _controller,
              onInsertImage: _insertImage,
            ),
          Expanded(
            child: _isEditing ? _buildEditor(isDark) : _buildPreview(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightSurface,
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        onChanged: (_) => setState(() {}), // 触发字数更新
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.75,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.writeMarkdownHere,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightSurface,
      child: Markdown(
        data: _controller.text,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: [ObsidianSyntax()],
        builders: {
          'obsidian_link':
              ObsidianLinkBuilder(context, widget.file.path, ref),
        },
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.inter(
            fontSize: 15,
            height: 1.75,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          h1: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          h2: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          h3: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          code: GoogleFonts.firaCode(
            fontSize: 13,
            backgroundColor: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceHigh,
          ),
        ),
        padding: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _insertImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final pickedImage = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final currentDir = p.dirname(widget.file.path);
      final newImagePath = p.join(currentDir, fileName);
      await pickedImage.copy(newImagePath);

      final text = _controller.text;
      final selection = _controller.selection;
      // Obsidian wiki 语法插入
      final obsidianInsert = '![[$fileName]]\n';

      if (selection.start >= 0 && selection.end >= 0) {
        final newText =
            text.replaceRange(selection.start, selection.end, obsidianInsert);
        _controller.value = _controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(
              offset: selection.start + obsidianInsert.length),
        );
      } else {
        _controller.text = text + obsidianInsert;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.imageInserted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 桌面端顶部栏
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopEditorTopBar extends StatelessWidget {
  final bool isDark;
  final File file;
  final bool isEditing;
  final bool isDetailOpen;
  final bool isSaving;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleDetail;
  final VoidCallback onSave;
  final AppLocalizations l10n;

  const _DesktopEditorTopBar({
    required this.isDark,
    required this.file,
    required this.isEditing,
    required this.isDetailOpen,
    required this.isSaving,
    required this.onToggleMode,
    required this.onToggleDetail,
    required this.onSave,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 52,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 面包屑
          Icon(Icons.folder_outlined, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            'VAULTS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(color: textSecondary, fontSize: 12)),
          ),
          Text(
            p.basename(file.path),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimaryAlt,
            ),
          ),
          const Spacer(),
          // 自动保存状态
          Text(
            isSaving ? 'Saving...' : 'Auto-saved',
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(width: 16),
          // 编辑/预览切换
          _TopBarIconButton(
            icon: isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
            tooltip: isEditing ? l10n.preview : l10n.edit,
            onTap: onToggleMode,
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          // 右侧详情面板开关
          _TopBarIconButton(
            icon: Icons.view_sidebar_outlined,
            tooltip: isDetailOpen ? 'Hide details' : 'Show details',
            onTap: onToggleDetail,
            isDark: isDark,
            isActive: isDetailOpen,
          ),
          const SizedBox(width: 12),
          // Save Changes 按钮
          _GradientButton(
            label: l10n.save,
            icon: Icons.save_outlined,
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 移动端顶部栏
// ══════════════════════════════════════════════════════════════════════════════

class _MobileEditorTopBar extends StatelessWidget {
  final bool isDark;
  final File file;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onToggleMode;
  final VoidCallback onSave;
  final AppLocalizations l10n;

  const _MobileEditorTopBar({
    required this.isDark,
    required this.file,
    required this.isEditing,
    required this.isSaving,
    required this.onToggleMode,
    required this.onSave,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return Container(
      height: 48,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.basename(file.path),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _TopBarIconButton(
            icon: isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
            tooltip: isEditing ? l10n.preview : l10n.edit,
            onTap: onToggleMode,
            isDark: isDark,
          ),
          _TopBarIconButton(
            icon: Icons.save_outlined,
            tooltip: l10n.save,
            onTap: onSave,
            isDark: isDark,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Markdown 格式化工具栏
// ══════════════════════════════════════════════════════════════════════════════

class _MarkdownToolbar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final VoidCallback? onInsertImage;

  const _MarkdownToolbar({
    required this.isDark,
    required this.controller,
    this.onInsertImage,
  });

  void _wrapSelection(String prefix, [String? suffix]) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start < 0) return;
    final selectedText = selection.textInside(text);
    final replacement = '$prefix$selectedText${suffix ?? prefix}';
    final newText = text.replaceRange(selection.start, selection.end, replacement);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + replacement.length,
      ),
    );
  }

  void _insertLine(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final pos = selection.start < 0 ? text.length : selection.start;
    final insert = '\n$prefix ';
    final newText = text.substring(0, pos) + insert + text.substring(pos);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF5F7FF);
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 40,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarBtn(icon: Icons.format_bold, tooltip: 'Bold', color: iconColor,
                onTap: () => _wrapSelection('**')),
            _ToolbarBtn(icon: Icons.format_italic, tooltip: 'Italic', color: iconColor,
                onTap: () => _wrapSelection('*')),
            _ToolbarBtn(icon: Icons.format_strikethrough, tooltip: 'Strikethrough', color: iconColor,
                onTap: () => _wrapSelection('~~')),
            _ToolbarDivider(),
            _ToolbarBtn(icon: Icons.format_quote, tooltip: 'Quote', color: iconColor,
                onTap: () => _insertLine('>')),
            _ToolbarBtn(icon: Icons.code, tooltip: 'Inline code', color: iconColor,
                onTap: () => _wrapSelection('`')),
            _ToolbarDivider(),
            _ToolbarBtn(icon: Icons.format_list_bulleted, tooltip: 'Bullet list', color: iconColor,
                onTap: () => _insertLine('-')),
            _ToolbarBtn(icon: Icons.format_list_numbered, tooltip: 'Numbered list', color: iconColor,
                onTap: () => _insertLine('1.')),
            _ToolbarDivider(),
            _ToolbarBtn(icon: Icons.image_outlined, tooltip: 'Insert image', color: iconColor,
                onTap: onInsertImage),
            _ToolbarBtn(icon: Icons.link, tooltip: 'Insert link', color: iconColor,
                onTap: () => _wrapSelection('[', '](url)')),
            _ToolbarBtn(icon: Icons.table_chart_outlined, tooltip: 'Insert table', color: iconColor,
                onTap: () {
                  const tableTemplate =
                      '\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n';
                  final pos = controller.selection.start < 0
                      ? controller.text.length
                      : controller.selection.start;
                  final newText = controller.text.substring(0, pos) +
                      tableTemplate +
                      controller.text.substring(pos);
                  controller.value = controller.value.copyWith(
                    text: newText,
                    selection: TextSelection.collapsed(
                        offset: pos + tableTemplate.length),
                  );
                }),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.lightBorder.withValues(alpha: 0.5),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 右侧文档详情面板（桌面）
// ══════════════════════════════════════════════════════════════════════════════

class _DocumentDetailPanel extends StatelessWidget {
  final bool isDark;
  final File file;
  final int wordCount;
  final int readingMinutes;
  final VoidCallback onSave;
  final bool isSaving;

  const _DocumentDetailPanel({
    required this.isDark,
    required this.file,
    required this.wordCount,
    required this.readingMinutes,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceLow;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fileName = p.basename(file.path);
    final extension = p.extension(file.path).replaceFirst('.', '').toUpperCase();

    return Container(
      width: 220,
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            'DOCUMENT DETAILS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // 文件名
          _DetailRow(
            label: 'FILE',
            value: fileName,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // 类型
          _DetailRow(
            label: 'TYPE',
            value: extension,
            isDark: isDark,
            valueWidget: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                extension,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimaryAlt,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 分割线（用 spacing 不用 Divider）
          Container(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 16),

          // 字数
          _DetailRow(
            label: 'WORDS',
            value: '$wordCount',
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // 阅读时间
          _DetailRow(
            label: 'READING TIME',
            value: '$readingMinutes min',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // 标签占位
          Text(
            'TAGS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag(label: 'markdown', isDark: isDark),
              _Tag(label: 'vault', isDark: isDark, color: AppColors.brandSecondary),
            ],
          ),
          const Spacer(),

          // Save Changes 按钮
          _GradientButton(
            label: 'Save Changes',
            icon: Icons.save_outlined,
            onTap: onSave,
            isLoading: isSaving,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Widget? valueWidget;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget ??
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color? color;

  const _Tag({required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final tagColor = color ?? AppColors.brandPrimaryAlt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: tagColor,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 共享组件
// ══════════════════════════════════════════════════════════════════════════════

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isActive;
  final bool isLoading;

  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? AppColors.brandPrimaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      icon,
                      size: 16,
                      color: isActive
                          ? AppColors.brandPrimaryAlt
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final double? width;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
