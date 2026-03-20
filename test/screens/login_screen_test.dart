// VaultClient 组件测试 - LoginScreen
// 测试登录界面的 UI 和交互

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/features/login/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('应该显示登录表单', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // 验证表单字段存在
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Obsidian Sync'), findsOneWidget);
      expect(find.text('Sync your notes with WebDAV'), findsOneWidget);
    });

    testWidgets('应该显示 WebDAV URL 输入框', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final urlField = find.widgetWithText(TextField, 'WebDAV URL');
      expect(urlField, findsOneWidget);
      
      // 验证默认值
      final textField = tester.widget<TextField>(urlField);
      expect(textField.controller?.text, contains('example.com'));
    });

    testWidgets('应该显示用户名输入框', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    });

    testWidgets('应该显示密码输入框', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final passwordField = find.widgetWithText(TextField, 'Password');
      expect(passwordField, findsOneWidget);
      
      // 验证密码是隐藏的
      final textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('应该显示登录按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      final loginButton = find.widgetWithText(FilledButton, 'Login & Sync');
      expect(loginButton, findsOneWidget);
    });

    testWidgets('应该允许输入文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // 输入 URL
      await tester.enterText(
        find.widgetWithText(TextField, 'WebDAV URL'),
        'https://myserver.com/webdav/',
      );

      // 输入用户名
      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'testuser',
      );

      // 输入密码
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'testpass',
      );

      await tester.pump();

      // 验证输入
      expect(find.text('https://myserver.com/webdav/'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('应该显示加载状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // 初始状态不应该有加载指示器
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 注意：要测试加载状态，需要 mock Provider 状态
      // 这需要在实际项目中实现
    });

    testWidgets('应该显示图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
