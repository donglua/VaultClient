import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/utils/error_util.dart';
import 'package:obsidian/l10n/app_localizations.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );
  }

  group('ErrorUtil.getFriendlyErrorMessage', () {
    testWidgets('returns accountExpired for account and expired keywords', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'Account has expired'),
        l10n.accountExpired,
      );
    });

    testWidgets('returns authFailed for Authentication or 401 keywords', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'Authentication failed'),
        l10n.authFailed,
      );
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'Error 401: Unauthorized'),
        l10n.authFailed,
      );
    });

    testWidgets('returns noPermission for 403 keyword', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, '403 Forbidden'),
        l10n.noPermission,
      );
    });

    testWidgets('returns fileNotFound for 404 keyword', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, '404 Not Found'),
        l10n.fileNotFound,
      );
    });

    testWidgets('returns networkTimeout for timeout or Timeout keywords', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'request timeout'),
        l10n.networkTimeout,
      );
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'TimeoutException'),
        l10n.networkTimeout,
      );
    });

    testWidgets('returns cannotConnect for Connection, connection or SocketException keywords', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'Connection refused'),
        l10n.cannotConnect,
      );
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'no connection'),
        l10n.cannotConnect,
      );
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'SocketException: OS Error'),
        l10n.cannotConnect,
      );
    });

    testWidgets('returns networkError for XMLHttpRequest error keyword', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final l10n = AppLocalizations.of(context)!;
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, 'XMLHttpRequest error'),
        l10n.networkError,
      );
    });

    testWidgets('returns original message if not matched and short', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      const error = 'Some random error message';
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, error),
        error,
      );
    });

    testWidgets('returns truncated message if not matched and long', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(createTestWidget(Builder(builder: (ctx) {
        context = ctx;
        return const SizedBox();
      })));

      final longError = 'A' * 150;
      final expected = '${'A' * 100}...';
      expect(
        ErrorUtil.getFriendlyErrorMessage(context, longError),
        expected,
      );
    });
  });
}
