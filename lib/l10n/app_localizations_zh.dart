// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'VaultClient';

  @override
  String get loginFailed => '登录失败';

  @override
  String get connectVault => '连接到你的 Vault';

  @override
  String get loginSubtitle => '输入 WebDAV 详情以同步 Markdown 笔记';

  @override
  String get webDavUrl => 'WebDAV 链接 (例如：https://example.com/webdav/)';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get loginAndSync => '登录并同步';

  @override
  String get footerText => '你的数据通过 WebDAV 安全存储';

  @override
  String get serverErrorCheckConfig => '无法连接到服务器，请检查配置和凭证。';

  @override
  String get accountExpired => '账号已过期，请续费后重试';

  @override
  String get authFailed => '认证失败，请检查账号和密码是否正确';

  @override
  String get noPermission => '无权限访问，请检查账号权限';

  @override
  String get fileNotFound => '远程文件或目录不存在';

  @override
  String get networkTimeout => '网络请求超时，请检查网络连接';

  @override
  String get cannotConnect => '无法连接到服务器，请检查网络和服务器地址';

  @override
  String get networkError => '网络请求错误，可能是跨域(CORS)限制或网络不通';

  @override
  String get syncSuccess => '同步成功！';

  @override
  String get syncFailed => '同步失败';

  @override
  String get retry => '重试';

  @override
  String get logoutTitle => '退出登录';

  @override
  String get logoutConfirm => '确定要退出当前账号吗？\n\n退出后需要重新输入 WebDAV 凭证。';

  @override
  String get cancel => '取消';

  @override
  String get logout => '退出';

  @override
  String get files => '文件';

  @override
  String get recent => '最近';

  @override
  String get obsidianVault => 'Obsidian 笔记库';

  @override
  String get writeMarkdownHere => '在这里输入 markdown 内容...';

  @override
  String get savedLocally => '已保存到本地';

  @override
  String get imageInserted => '已插入图片';

  @override
  String get insertImage => '插入图片';

  @override
  String get preview => '预览';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';
}
