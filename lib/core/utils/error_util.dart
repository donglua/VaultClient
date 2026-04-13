import 'package:flutter/widgets.dart';
import 'package:obsidian/l10n/app_localizations.dart';

class ErrorUtil {
  /// 将原始错误信息转换为对用户友好的本地化提示
  static String getFriendlyErrorMessage(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;

    if (error.contains('Account') && error.contains('expired')) {
      return l10n.accountExpired;
    } else if (error.contains('Authentication') || error.contains('401')) {
      return l10n.authFailed;
    } else if (error.contains('403')) {
      return l10n.noPermission;
    } else if (error.contains('404')) {
      return l10n.fileNotFound;
    } else if (error.contains('timeout') || error.contains('Timeout')) {
      return l10n.networkTimeout;
    } else if (error.contains('Connection') ||
        error.contains('connection') ||
        error.contains('SocketException')) {
      return l10n.cannotConnect;
    } else if (error.contains('XMLHttpRequest error')) {
      return l10n.networkError;
    } else {
      // 截取错误消息前 100 字符，避免过长的无意义堆栈信息
      final msg = error.length > 100 ? '${error.substring(0, 100)}...' : error;
      return msg;
    }
  }
}
