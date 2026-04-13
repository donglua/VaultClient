// VaultClient 组件测试 - LoginScreen
// 测试登录界面的 UI 和交互

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/features/login/presentation/providers/login_provider.dart';
import 'package:obsidian/features/login/presentation/screens/login_screen.dart';
import 'package:obsidian/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _FakeWebDAVLoginNotifier extends WebDAVLoginNotifier {
  @override
  Future<bool> checkExistingLogin() async {
    return false;
  }

  @override
  Future<bool> login(String url, String username, String password) async {
    state = state.copyWith(isLoading: false, error: null);
    return false;
  }

  @override
  Future<void> logout() async {
    state = WebDAVLoginState();
  }
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      webdavLoginProvider.overrideWith(() => _FakeWebDAVLoginNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
      home: const Scaffold(body: LoginScreen()),
    ),
  );
}

Future<void> _pumpLoginScreen(WidgetTester tester) async {
  await tester.pumpWidget(_buildTestApp());
  // 等待首帧与异步 checkExistingLogin 完成，避免瞬时状态抖动。
  await tester.pumpAndSettle();
}

void main() {
  group('LoginScreen', () {
    testWidgets('应该显示登录表单', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      // 验证表单字段存在
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('VaultClient'), findsOneWidget);
      expect(
        find.text('Professional Knowledge Infrastructure'),
        findsOneWidget,
      );
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示 WebDAV URL 输入框', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      final textFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(textFields.length, 3);

      // 验证默认值
      expect(textFields[0].controller?.text, contains('example.com'));
      expect(
        find.text('WEBDAV URL (E.G., HTTPS://EXAMPLE.COM/WEBDAV/)'),
        findsOneWidget,
      );
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示用户名输入框', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      expect(find.text('USERNAME'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示密码输入框', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      expect(find.text('PASSWORD'), findsOneWidget);

      // 验证密码是隐藏的
      final textFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(textFields[2].obscureText, isTrue);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示登录按钮', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      expect(find.text('Sign In to Vault'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该允许输入文本', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      // 输入 URL
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'https://myserver.com/webdav/');

      // 输入用户名
      await tester.enterText(fields.at(1), 'testuser');

      // 输入密码
      await tester.enterText(fields.at(2), 'testpass');

      await tester.pump();

      // 验证输入
      expect(find.text('https://myserver.com/webdav/'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示加载状态', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      // 初始状态不应该有加载指示器
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('应该显示图标', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await _pumpLoginScreen(tester);

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
