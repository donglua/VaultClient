import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/sync_engine.dart';

final webdavLoginProvider = NotifierProvider<WebDAVLoginNotifier, WebDAVLoginState>(() {
  return WebDAVLoginNotifier();
});

class WebDAVLoginState {
  final bool isLoading;
  final String? error;

  WebDAVLoginState({this.isLoading = false, this.error});

  WebDAVLoginState copyWith({bool? isLoading, String? error}) {
    return WebDAVLoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WebDAVLoginNotifier extends Notifier<WebDAVLoginState> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  WebDAVLoginState build() {
    return WebDAVLoginState();
  }

  Future<bool> login(String url, String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final webdavService = ref.read(webdavServiceProvider);
      webdavService.init(url, username, password);

      final pingSuccess = await webdavService.ping();
      if (pingSuccess) {
        // Securely store credentials using flutter_secure_storage
        await _secureStorage.write(key: 'webdav_url', value: url);
        await _secureStorage.write(key: 'webdav_username', value: username);
        await _secureStorage.write(key: 'webdav_password', value: password);

        // Also clean up any insecurely stored credentials if they exist
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('webdav_url');
        await prefs.remove('webdav_username');
        await prefs.remove('webdav_password');

        // Trigger initial sync to pull remote files
        try {
          final syncEngine = ref.read(syncEngineProvider);
          await syncEngine.syncVault('');
        } catch (syncError) {
          print('[LoginProvider] Initial sync failed: $syncError');
          // Continue anyway, user can manually sync later
        }

        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to connect. Please check credentials.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 退出登录，清除所有凭证
  Future<void> logout() async {
    await _secureStorage.delete(key: 'webdav_url');
    await _secureStorage.delete(key: 'webdav_username');
    await _secureStorage.delete(key: 'webdav_password');
    
    // Also clean up SharedPreferences if exists
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('webdav_url');
    await prefs.remove('webdav_username');
    await prefs.remove('webdav_password');
    
    // Reset state
    state = WebDAVLoginState();
  }

  Future<bool> checkExistingLogin() async {
    String? url = await _secureStorage.read(key: 'webdav_url');
    String? username = await _secureStorage.read(key: 'webdav_username');
    String? password = await _secureStorage.read(key: 'webdav_password');

    // If not in secure storage, check SharedPreferences for migration
    if (url == null || username == null || password == null) {
      final prefs = await SharedPreferences.getInstance();
      final oldUrl = prefs.getString('webdav_url');
      final oldUsername = prefs.getString('webdav_username');
      final oldPassword = prefs.getString('webdav_password');

      if (oldUrl != null && oldUsername != null && oldPassword != null) {
        // Migrate to secure storage
        await _secureStorage.write(key: 'webdav_url', value: oldUrl);
        await _secureStorage.write(key: 'webdav_username', value: oldUsername);
        await _secureStorage.write(key: 'webdav_password', value: oldPassword);

        // Remove from insecure storage
        await prefs.remove('webdav_url');
        await prefs.remove('webdav_username');
        await prefs.remove('webdav_password');

        url = oldUrl;
        username = oldUsername;
        password = oldPassword;
      }
    }

    if (url != null && username != null && password != null) {
      final webdavService = ref.read(webdavServiceProvider);
      webdavService.init(url, username, password);
      return await webdavService.ping();
    }
    return false;
  }
}
