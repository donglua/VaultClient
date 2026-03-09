import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_provider.dart';
import '../../main_ui/screens/main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});




  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlController = TextEditingController(text: 'https://example.com/webdav/');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final isLoggedIn = await ref.read(webdavLoginProvider.notifier).checkExistingLogin();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
    }
  }

  void _login() async {
    final success = await ref.read(webdavLoginProvider.notifier).login(
      _urlController.text,
      _usernameController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(webdavLoginProvider).error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webdavLoginProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Obsidian WebDAV Sync')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'WebDAV URL'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            state.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login & Sync'),
                  ),
          ],
        ),
      ),
    );
  }
}
