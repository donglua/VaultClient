import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('webdav_url', url);
        await prefs.setString('webdav_username', username);
        await prefs.setString('webdav_password', password);

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

  Future<bool> checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url');
    final username = prefs.getString('webdav_username');
    final password = prefs.getString('webdav_password');

    if (url != null && username != null && password != null) {
      final webdavService = ref.read(webdavServiceProvider);
      webdavService.init(url, username, password);
      return await webdavService.ping();
    }
    return false;
  }
}
