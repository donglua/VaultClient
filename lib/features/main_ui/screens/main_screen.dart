import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/file_tree_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../../core/services/sync_engine.dart';
import '../../login/providers/login_provider.dart';
import '../../login/screens/login_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  bool _isSyncing = false;
  Timer? _syncTimer;
  bool _isDrawerOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSyncTimer();
    // 在第一帧渲染后自动同步并刷新文件树
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _manualSync(silent: true);
      // 同步完成后强制刷新 UI
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
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopSyncTimer();
    }
  }

  void _startSyncTimer() {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
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
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.syncVault('/');
      ref.read(fileTreeNotifierProvider.notifier).refresh();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('同步成功！'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (!silent && mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        final errorMsg = _getFriendlyErrorMessage(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('同步失败', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(errorMsg, style: const TextStyle(fontSize: 13)),
            ],
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: () => _manualSync(silent: true),
          ),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// 友好的错误消息转换
  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Account') && error.contains('expired')) {
      return '账号已过期，请续费后重试';
    } else if (error.contains('Authentication') || error.contains('401')) {
      return '认证失败，请检查账号密码';
    } else if (error.contains('403')) {
      return '无权限访问，请检查账号权限';
    } else if (error.contains('404')) {
      return '远程目录不存在';
    } else if (error.contains('timeout') || error.contains('Timeout')) {
      return '网络超时，请检查网络连接';
    } else if (error.contains('Connection') || error.contains('connection')) {
      return '无法连接服务器，请检查网络';
    } else {
      // 截取错误消息前 100 字符
      final msg = error.length > 100 ? '${error.substring(0, 100)}...' : error;
      return msg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Side Navigation Rail
        NavigationRail(
          extended: _isDrawerOpen,
          minWidth: 72,
          minExtendedWidth: 240,
          leading: Column(
            children: [
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _isDrawerOpen = !_isDrawerOpen),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary),
                  if (_isDrawerOpen) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Vault',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
          trailing: Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return Column(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: _isSyncing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                    onPressed: _isSyncing ? null : _manualSync,
                    tooltip: 'Sync',
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                    tooltip: 'Settings',
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: _showLogoutDialog,
                    tooltip: 'Logout',
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          selectedIndex: 0,
          onDestinationSelected: (index) {},
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.folder),
              label: Text('Files'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.history),
              label: Text('Recent'),
            ),
          ],
        ),
        // File Tree Panel
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isDrawerOpen ? 280 : 0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: _isDrawerOpen ? _FileTreeWidget() : null,
        ),
        // Editor Area
        Expanded(
          child: _EditorArea(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        AppBar(
          title: const Text('Obsidian Vault'),
          actions: [
            _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _manualSync,
                ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _showLogoutDialog,
              tooltip: 'Logout',
            ),
          ],
        ),
        Expanded(child: _FileTreeWidget()),
      ],
    );
  }

  /// 显示退出确认对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 48),
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？\n\n退出后需要重新输入 WebDAV 凭证。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }

  /// 执行退出操作
  void _logout() {
    // 清除登录凭证
    ref.read(webdavLoginProvider.notifier).logout();
    
    // 返回登录页
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Empty Vault',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final entity = files[index];
        final name = p.basename(entity.path);
        final isDir = entity is Directory;

        if (isDir) {
          final isExpanded = _expandedFolders.contains(entity.path);
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedFolders.remove(entity.path);
                    } else {
                      _expandedFolders.add(entity.path);
                    }
                  });
                },
              ),
              // 如果展开，显示子文件和子文件夹
              if (isExpanded) ..._buildSubFiles(entity as Directory, colorScheme),
            ],
          );
        } else {
          // 文件项
          return ListTile(
            leading: Icon(
              Icons.description_rounded,
              color: colorScheme.secondary,
            ),
            title: Text(name),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              if (name.endsWith('.md')) {
                ref.read(selectedFileProvider.notifier).selectFile(entity as File);
                if (MediaQuery.of(context).size.width < 800) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditorScreen(file: entity)),
                  );
                }
              }
            },
          );
        }
      },
    );
  }

  /// 递归构建子文件和子文件夹
  List<Widget> _buildSubFiles(Directory dir, ColorScheme colorScheme) {
    final subWidgets = <Widget>[];
    try {
      final subEntities = dir.listSync(recursive: false, followLinks: false);
      // 排序：文件夹在前，文件在后，按名称排序
      subEntities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });

      for (final entity in subEntities) {
        final name = p.basename(entity.path);
        final isDir = entity is Directory;

        if (isDir) {
          final isExpanded = _expandedFolders.contains(entity.path);
          subWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListTile(
                leading: Icon(
                  isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedFolders.remove(entity.path);
                    } else {
                      _expandedFolders.add(entity.path);
                    }
                  });
                },
              ),
            ),
          );
          // 递归显示子内容
          if (isExpanded) {
            subWidgets.addAll(_buildSubFiles(entity as Directory, colorScheme));
          }
        } else if (name.endsWith('.md')) {
          // 只显示 .md 文件
          subWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListTile(
                leading: Icon(
                  Icons.description_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  ref.read(selectedFileProvider.notifier).selectFile(entity as File);
                  if (MediaQuery.of(context).size.width < 800) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditorScreen(file: entity)),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error reading subfiles of ${dir.path}: $e');
    }
    return subWidgets;
  }
}

class _EditorArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Select a file to edit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a markdown file from the sidebar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return EditorScreen(file: selectedFile, isDesktop: true);
  }
}
