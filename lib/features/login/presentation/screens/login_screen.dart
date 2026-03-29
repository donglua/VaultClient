import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:obsidian/l10n/app_localizations.dart';
import '../../../../main.dart';
import '../providers/login_provider.dart';
import '../../../main_ui/presentation/screens/main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlController = TextEditingController(
    text: 'https://example.com/webdav/',
  );
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkLogin() async {
    final isLoggedIn = await ref
        .read(webdavLoginProvider.notifier)
        .checkExistingLogin();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  void _login() async {
    final success = await ref.read(webdavLoginProvider.notifier).login(
      _urlController.text,
      _usernameController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else if (mounted) {
      final error = ref.read(webdavLoginProvider).error;
      String errorMessage = AppLocalizations.of(context)!.loginFailed;
      if (error != null) {
        if (error == 'serverErrorCheckConfig') {
          errorMessage = AppLocalizations.of(context)!.serverErrorCheckConfig;
        } else {
          errorMessage = error;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webdavLoginProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F4FF),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBg, AppColors.darkSurface]
                : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _LoginCard(
                  l10n: l10n,
                  isDark: isDark,
                  state: state,
                  urlController: _urlController,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onLogin: state.isLoading ? null : _login,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 登录卡片组件
class _LoginCard extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final dynamic state;
  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onLogin;

  const _LoginCard({
    required this.l10n,
    required this.isDark,
    required this.state,
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0053D4).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo + 品牌标识
          _buildBrandHeader(context),
          const SizedBox(height: 36),

          // 表单字段
          _buildFieldLabel(context, l10n.webDavUrl),
          const SizedBox(height: 6),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: 'https://vault.example.com/webdav/',
              prefixIcon: const Icon(Icons.dns_rounded, size: 18),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(context, l10n.username),
          const SizedBox(height: 6),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: 'username',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(context, l10n.password),
          const SizedBox(height: 6),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14),
            onSubmitted: (_) => onLogin?.call(),
          ),
          const SizedBox(height: 28),

          // 登录按钮
          _buildLoginButton(context),
          const SizedBox(height: 20),

          // 加密标识
          _buildEncryptedBadge(context),
          const SizedBox(height: 20),

          // 页脚
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Column(
      children: [
        // 盾牌图标背景
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'VaultClient',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Professional Knowledge Infrastructure',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return state.isLoading
        ? const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogin,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In to Vault',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildEncryptedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            'END-TO-END ENCRYPTED ENVIRONMENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(label: 'Privacy Policy'),
        _FooterDivider(),
        _FooterLink(label: 'System Status'),
        _FooterDivider(),
        _FooterLink(label: 'Contact Support'),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.lightTextTertiary,
      ),
    );
  }
}

class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(color: AppColors.lightTextTertiary),
      ),
    );
  }
}
