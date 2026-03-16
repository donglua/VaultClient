import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/file_tree_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../../core/services/sync_engine.dart';

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
          content: const Text('Sync complete!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync failed: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          trailing: Column(
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
            ],
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
          ],
        ),
        Expanded(child: _FileTreeWidget()),
      ],
    );
  }
}

class _FileTreeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        return ListTile(
          leading: Icon(
            isDir ? Icons.folder_rounded : Icons.description_rounded,
            color: isDir ? colorScheme.primary : colorScheme.secondary,
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isDir ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: isDir ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () {
            if (!isDir && name.endsWith('.md')) {
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
      },
    );
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
