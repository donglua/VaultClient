import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'VaultClient'**
  String get appTitle;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @connectVault.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Vault'**
  String get connectVault;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your WebDAV details to sync your markdown notes.'**
  String get loginSubtitle;

  /// No description provided for @webDavUrl.
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL (e.g., https://example.com/webdav/)'**
  String get webDavUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginAndSync.
  ///
  /// In en, this message translates to:
  /// **'Login & Sync'**
  String get loginAndSync;

  /// No description provided for @footerText.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely via WebDAV'**
  String get footerText;

  /// No description provided for @serverErrorCheckConfig.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to the server, please check configuration and credentials.'**
  String get serverErrorCheckConfig;

  /// No description provided for @accountExpired.
  ///
  /// In en, this message translates to:
  /// **'Account has expired, please renew and try again'**
  String get accountExpired;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed, please check username and password'**
  String get authFailed;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission to access, please check account permissions'**
  String get noPermission;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Remote file or directory does not exist'**
  String get fileNotFound;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Network request timed out, please check network connection'**
  String get networkTimeout;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server, please check network and server address'**
  String get cannotConnect;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network request error, possibly CORS restriction or network unreachable'**
  String get networkError;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync successful!'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of the current account?\n\nYou will need to re-enter WebDAV credentials after logging out.'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @obsidianVault.
  ///
  /// In en, this message translates to:
  /// **'Obsidian Vault'**
  String get obsidianVault;

  /// No description provided for @writeMarkdownHere.
  ///
  /// In en, this message translates to:
  /// **'Write your markdown here...'**
  String get writeMarkdownHere;

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get savedLocally;

  /// No description provided for @imageInserted.
  ///
  /// In en, this message translates to:
  /// **'Image inserted'**
  String get imageInserted;

  /// No description provided for @insertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert Image'**
  String get insertImage;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @vaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultLabel;

  /// No description provided for @syncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @emptyVault.
  ///
  /// In en, this message translates to:
  /// **'Empty Vault'**
  String get emptyVault;

  /// No description provided for @selectFileToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select a file to edit'**
  String get selectFileToEdit;

  /// No description provided for @selectMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a markdown file from the sidebar'**
  String get selectMarkdownHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
