// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VaultClient';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get connectVault => 'Connect to your Vault';

  @override
  String get loginSubtitle =>
      'Enter your WebDAV details to sync your markdown notes.';

  @override
  String get webDavUrl => 'WebDAV URL (e.g., https://example.com/webdav/)';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginAndSync => 'Login & Sync';

  @override
  String get footerText => 'Your data is stored securely via WebDAV';

  @override
  String get serverErrorCheckConfig =>
      'Cannot connect to the server, please check configuration and credentials.';

  @override
  String get accountExpired =>
      'Account has expired, please renew and try again';

  @override
  String get authFailed =>
      'Authentication failed, please check username and password';

  @override
  String get noPermission =>
      'No permission to access, please check account permissions';

  @override
  String get fileNotFound => 'Remote file or directory does not exist';

  @override
  String get networkTimeout =>
      'Network request timed out, please check network connection';

  @override
  String get cannotConnect =>
      'Cannot connect to server, please check network and server address';

  @override
  String get networkError =>
      'Network request error, possibly CORS restriction or network unreachable';

  @override
  String get syncSuccess => 'Sync successful!';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get retry => 'Retry';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutConfirm =>
      'Are you sure you want to log out of the current account?\n\nYou will need to re-enter WebDAV credentials after logging out.';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Logout';

  @override
  String get files => 'Files';

  @override
  String get recent => 'Recent';

  @override
  String get obsidianVault => 'Obsidian Vault';

  @override
  String get writeMarkdownHere => 'Write your markdown here...';

  @override
  String get savedLocally => 'Saved locally';

  @override
  String get imageInserted => 'Image inserted';

  @override
  String get insertImage => 'Insert Image';

  @override
  String get preview => 'Preview';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';
}
