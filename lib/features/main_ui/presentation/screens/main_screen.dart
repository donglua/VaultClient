import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:obsidian/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import '../providers/file_tree_provider.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/utils/error_util.dart';
import '../../../login/presentation/providers/login_provider.dart';
import '../../../login/presentation/screens/login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/gradient_button.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  bool _isSyncing = false;
  Timer? _syncTimer;
  bool _isSidebarOpen = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSyncTimer();
    // 在第一帧渲染后自动同步并刷新文件树
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(fileTreeNotifierProvider.notifier).refresh();
      await _manualSync(silent: true);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSyncTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSyncTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopSyncTimer();
    }
  }

  void _startSyncTimer() {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _manualSync(silent: true);
      });
    }
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _manualSync({bool silent = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final syncEngine = ref.read(syncEngineProvider);
      final result = await syncEngine.syncVault('/');
      ref.read(fileTreeNotifierProvider.notifier).refresh();
      if (!silent && mounted) {
        _showSyncSuccessSnackBar(result);
      }
    } catch (e) {
      if (!silent && mounted) {
        _showSyncErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showSyncSuccessSnackBar(dynamic result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.syncSuccess,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '↓${result.downloadedCount}  ✓${result.scannedCount}  ${result.elapsed.inMilliseconds}ms',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSyncErrorSnackBar(dynamic e) {
    final errorMsg = ErrorUtil.getFriendlyErrorMessage(context, e.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.syncFailed,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(errorMsg, style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.retry,
          onPressed: () => _manualSync(silent: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ─────────────────────────── 桌面三栏布局 ───────────────────────────

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // 左侧导航栏（窄条，固定图标导航）
        _DesktopNavRail(
          isDark: isDark,
          isSidebarOpen: _isSidebarOpen,
          selectedIndex: _selectedNavIndex,
          isSyncing: _isSyncing,
          onToggleSidebar: () =>
              setState(() => _isSidebarOpen = !_isSidebarOpen),
          onNavSelected: (i) => setState(() => _selectedNavIndex = i),
          onSync: _isSyncing ? null : _manualSync,
          onLogout: _showLogoutDialog,
        ),
        // 文件树面板（可收起）
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: _isSidebarOpen ? 260 : 0,
          child: _isSidebarOpen
              ? _FilePanel(isDark: isDark)
              : const SizedBox.shrink(),
        ),
        // 主编辑区
        Expanded(child: _EditorArea()),
      ],
    );
  }

  // ─────────────────────────── 移动端布局 ───────────────────────────

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // 顶部 AppBar
        _MobileTopBar(
          isDark: isDark,
          isSyncing: _isSyncing,
          onSync: _isSyncing ? null : _manualSync,
          onLogout: _showLogoutDialog,
          l10n: l10n,
        ),
        // 内容区（文件树 or 编辑器）
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final selectedFile = ref.watch(selectedFileProvider);
              // 移动端：有选中文件时展示编辑器的底部back按钮由EditorScreen自带
              if (selectedFile != null) {
                return Column(
                  children: [
                    // 面包屑导航
                    _MobileBreadcrumb(
                      file: selectedFile,
                      isDark: isDark,
                      onBack: () => ref
                          .read(selectedFileProvider.notifier)
                          .selectFile(null),
                    ),
                    Expanded(
                      child: EditorScreen(file: selectedFile, isDesktop: false),
                    ),
                  ],
                );
              }
              return _FilePanel(isDark: isDark, compact: true);
            },
          ),
        ),
        // 底部新建 FAB 占位
        _MobileBottomBar(isDark: isDark),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Icon(Icons.logout_rounded, color: AppColors.error, size: 40),
          title: Text(
            l10n.logoutTitle,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
          content: Text(
            l10n.logoutConfirm,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _logout();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    ref.read(webdavLoginProvider.notifier).logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 桌面端导航栏
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopNavRail extends StatelessWidget {
  final bool isDark;
  final bool isSidebarOpen;
  final int selectedIndex;
  final bool isSyncing;
  final VoidCallback onToggleSidebar;
  final ValueChanged<int> onNavSelected;
  final VoidCallback? onSync;
  final VoidCallback onLogout;

  const _DesktopNavRail({
    required this.isDark,
    required this.isSidebarOpen,
    required this.selectedIndex,
    required this.isSyncing,
    required this.onToggleSidebar,
    required this.onNavSelected,
    required this.onSync,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final activeColor = AppColors.brandPrimaryAlt;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: 64,
      color: bg,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 20),
          // 收起/展开侧栏按钮
          _NavIconButton(
            icon: isSidebarOpen
                ? Icons.view_sidebar_outlined
                : Icons.view_sidebar,
            tooltip: isSidebarOpen ? 'Collapse sidebar' : 'Expand sidebar',
            onTap: onToggleSidebar,
            color: inactiveColor,
          ),
          const SizedBox(height: 4),
          // 文件导航
          _NavIconButton(
            icon: Icons.folder_outlined,
            tooltip: 'Files',
            onTap: () => onNavSelected(0),
            color: selectedIndex == 0 ? activeColor : inactiveColor,
            isActive: selectedIndex == 0,
          ),
          const SizedBox(height: 4),
          // 最近
          _NavIconButton(
            icon: Icons.history_rounded,
            tooltip: 'Recent',
            onTap: () => onNavSelected(1),
            color: selectedIndex == 1 ? activeColor : inactiveColor,
            isActive: selectedIndex == 1,
          ),
          const Spacer(),
          // 同步按钮
          _NavIconButton(
            icon: Icons.sync_rounded,
            tooltip: 'Sync',
            onTap: onSync,
            color: inactiveColor,
            isLoading: isSyncing,
          ),
          const SizedBox(height: 4),
          // 设置
          _NavIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () {},
            color: inactiveColor,
          ),
          const SizedBox(height: 4),
          // 退出
          _NavIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onTap: onLogout,
            color: AppColors.error,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final bool isActive;
  final bool isLoading;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: isActive ? AppColors.brandPrimaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 文件树面板
// ══════════════════════════════════════════════════════════════════════════════

class _FilePanel extends StatelessWidget {
  final bool isDark;
  final bool compact;

  const _FilePanel({required this.isDark, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceLow;
    return Container(
      color: bg,
      child: Column(
        children: [
          if (!compact) _FilePanelHeader(isDark: isDark),
          Expanded(child: _FileTreeWidget()),
        ],
      ),
    );
  }
}

class _FilePanelHeader extends StatelessWidget {
  final bool isDark;
  const _FilePanelHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 16,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.vaultLabel,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 移动端顶部栏
// ══════════════════════════════════════════════════════════════════════════════

class _MobileTopBar extends StatelessWidget {
  final bool isDark;
  final bool isSyncing;
  final VoidCallback? onSync;
  final VoidCallback onLogout;
  final AppLocalizations l10n;

  const _MobileTopBar({
    required this.isDark,
    required this.isSyncing,
    required this.onSync,
    required this.onLogout,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'VaultClient',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          // 同步按钮
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 20),
              onPressed: onSync,
              tooltip: l10n.syncTooltip,
            ),
          IconButton(
            icon: Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
            onPressed: onLogout,
            tooltip: l10n.logoutTitle,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 移动端面包屑
// ══════════════════════════════════════════════════════════════════════════════

class _MobileBreadcrumb extends StatelessWidget {
  final File file;
  final bool isDark;
  final VoidCallback onBack;

  const _MobileBreadcrumb({
    required this.file,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(file.path);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceLow,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.description_outlined,
            size: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fileName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 移动端底部栏
// ══════════════════════════════════════════════════════════════════════════════

class _MobileBottomBar extends StatelessWidget {
  final bool isDark;
  const _MobileBottomBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          // "+ New Entry" 按钮
          GradientButton(
            label: 'New Entry',
            icon: Icons.add,
            onTap: () {}, // 待实现新建功能
            borderRadius: 20.0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            iconSize: 16.0,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 文件树 Widget
// ══════════════════════════════════════════════════════════════════════════════

class _FileTreeWidget extends ConsumerStatefulWidget {
  @override
  _FileTreeWidgetState createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends ConsumerState<_FileTreeWidget> {
  // 记录展开的文件夹路径
  final Set<String> _expandedFolders = {};

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(fileTreeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.emptyVault,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final entity = files[index];
        final name = p.basename(entity.path);

        if (entity is Directory) {
          return _buildFolderItem(entity, name, 0, isDark);
        }
        return _buildFileItem(entity as File, name, 0, isDark);
      },
    );
  }

  Widget _buildFolderItem(Directory dir, String name, int depth, bool isDark) {
    final isExpanded = _expandedFolders.contains(dir.path);
    final activeColor = AppColors.brandPrimaryAlt;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TreeItemTile(
          depth: depth,
          icon: isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined,
          iconColor: activeColor,
          label: name,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          trailing: Icon(
            isExpanded
                ? Icons.expand_more_rounded
                : Icons.chevron_right_rounded,
            size: 16,
            color: inactiveColor,
          ),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedFolders.remove(dir.path);
              } else {
                _expandedFolders.add(dir.path);
              }
            });
          },
          isDark: isDark,
        ),
        if (isExpanded) ..._buildSubItems(dir, depth + 1, isDark),
      ],
    );
  }

  Widget _buildFileItem(File file, String name, int depth, bool isDark) {
    final selectedFile = ref.watch(selectedFileProvider);
    final isSelected = selectedFile?.path == file.path;
    return _TreeItemTile(
      depth: depth,
      icon: Icons.description_outlined,
      iconColor: isSelected
          ? AppColors.brandPrimaryAlt
          : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
      label: name,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected
            ? AppColors.brandPrimaryAlt
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      ),
      isSelected: isSelected,
      onTap: () {
        if (name.endsWith('.md')) {
          ref.read(selectedFileProvider.notifier).selectFile(file);
          if (MediaQuery.of(context).size.width < 800) {
            // 移动端：直接更新状态，父级 Consumer 会显示编辑器
          }
        }
      },
      isDark: isDark,
    );
  }

  List<Widget> _buildSubItems(Directory dir, int depth, bool isDark) {
    final widgets = <Widget>[];
    try {
      final subEntities = dir.listSync(recursive: false, followLinks: false);
      subEntities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });

      for (final entity in subEntities) {
        final name = p.basename(entity.path);
        if (entity is Directory) {
          widgets.add(_buildFolderItem(entity, name, depth, isDark));
        } else if (name.endsWith('.md')) {
          widgets.add(_buildFileItem(entity as File, name, depth, isDark));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading subfiles of ${dir.path}: $e');
      }
    }
    return widgets;
  }
}

/// 文件树通用行组件
class _TreeItemTile extends StatelessWidget {
  final int depth;
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextStyle labelStyle;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;

  const _TreeItemTile({
    required this.depth,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelStyle,
    required this.onTap,
    required this.isDark,
    this.trailing,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.brandPrimaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 34,
          padding: EdgeInsets.only(left: 8.0 + depth * 16.0, right: 8),
          // 激活项左侧蓝色竖条
          decoration: isSelected
              ? BoxDecoration(
                  border: const Border(
                    left: BorderSide(
                      color: AppColors.brandPrimaryAlt,
                      width: 3,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: labelStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 编辑区域（桌面模式右侧）
// ══════════════════════════════════════════════════════════════════════════════

class _EditorArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (selectedFile == null) {
      return _EmptyEditorPlaceholder(isDark: isDark);
    }

    return EditorScreen(file: selectedFile, isDesktop: true);
  }
}

class _EmptyEditorPlaceholder extends StatelessWidget {
  final bool isDark;
  const _EmptyEditorPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.edit_document,
              size: 36,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.selectFileToEdit,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectMarkdownHint,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
