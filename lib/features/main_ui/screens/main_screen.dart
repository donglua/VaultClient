import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/file_tree_provider.dart';
import '../../editor/screens/editor_screen.dart';
import '../../../core/services/sync_engine.dart';

/// The main layout screen for the Obsidian sync client.
/// Uses a responsive design: a split pane on large screens (desktop/tablet)
/// and a single pane that pushes the editor on smaller screens (mobile).
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  bool _isSyncing = false;
  Timer? _syncTimer;

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
    // Resume syncing only when the app is active in the foreground.
    if (state == AppLifecycleState.resumed) {
      _startSyncTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Stop the timer when the app is placed in the background or killed.
      _stopSyncTimer();
    }
  }

  /// Starts the periodic sync timer if it is not already running.
  void _startSyncTimer() {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
        // Trigger a silent sync every 5 minutes
        _manualSync(silent: true);
      });
    }
  }

  /// Stops the active sync timer.
  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Triggers a manual synchronization via the [SyncEngine].
  ///
  /// [silent] determines whether UI feedback (Snackbars) will be shown.
  /// Used internally for periodic background syncing to prevent spamming the user.
  Future<void> _manualSync({bool silent = false}) async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncEngine = ref.read(syncEngineProvider);
      // In a real app, you might want to sync to a specific remote folder instead of root.
      await syncEngine.syncVault('/');
      ref.read(fileTreeNotifierProvider.notifier).refresh();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync complete!')));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
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
    // Determine layout based on width
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Obsidian Vault'),
        actions: [
          _isSyncing
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : IconButton(
                icon: Icon(Icons.sync),
                onPressed: _manualSync,
              ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: _FileTreeWidget(),
        ),
        VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _EditorArea(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _FileTreeWidget();
  }
}

class _FileTreeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileTreeNotifierProvider);

    if (files.isEmpty) {
      return Center(child: Text('Empty Vault'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final entity = files[index];
        final name = p.basename(entity.path);
        final isDir = entity is Directory;

        return ListTile(
          leading: Icon(isDir ? Icons.folder : Icons.description),
          title: Text(name),
          onTap: () {
            if (!isDir && name.endsWith('.md')) {
              ref.read(selectedFileProvider.notifier).selectFile(entity as File);

              if (MediaQuery.of(context).size.width < 800) {
                // Mobile: push new screen
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

    if (selectedFile == null) {
      return Center(child: Text('Select a file to edit/preview'));
    }

    return EditorScreen(file: selectedFile, isDesktop: true);
  }
}
