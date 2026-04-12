import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian/core/utils/error_util.dart';
import 'package:obsidian/l10n/app_localizations.dart';

void main() {
  testWidgets('ErrorUtil.getFriendlyErrorMessage returns localized messages', (WidgetTester tester) async {
    late BuildContext testContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(testContext)!;

    // Test: Account expired
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Your Account has expired'),
      l10n.accountExpired,
    );

    // Test: Authentication failed
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Authentication failed'),
      l10n.authFailed,
    );
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Error 401: Unauthorized'),
      l10n.authFailed,
    );

    // Test: No permission
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Error 403: Forbidden'),
      l10n.noPermission,
    );

    // Test: File not found
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Error 404: Not Found'),
      l10n.fileNotFound,
    );

    // Test: Network timeout
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'The connection timeout occurred'),
      l10n.networkTimeout,
    );
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Timeout while connecting'),
      l10n.networkTimeout,
    );

    // Test: Cannot connect
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'Connection refused'),
      l10n.cannotConnect,
    );
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'lost connection'),
      l10n.cannotConnect,
    );
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'SocketException: host unreachable'),
      l10n.cannotConnect,
    );

    // Test: Network error
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, 'XMLHttpRequest error'),
      l10n.networkError,
    );

    // Test: Unknown error (not truncated)
    const shortError = 'Unknown error occurred';
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, shortError),
      shortError,
    );

    // Test: Long error (truncated)
    final longError = 'A' * 101;
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, longError),
      '${'A' * 100}...',
    );

    // Test: Exactly 100 characters (not truncated)
    final hundredCharError = 'B' * 100;
    expect(
      ErrorUtil.getFriendlyErrorMessage(testContext, hundredCharError),
      hundredCharError,
    );
  });
}
