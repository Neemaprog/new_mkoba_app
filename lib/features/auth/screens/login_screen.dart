import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/translation_extension.dart';
import '../auth_service.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('fill_all_fields'.tr(context));
      return;
    }
    setState(() => _isLoading = true);
    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (result['success']) {
      // Pata role kutoka kwenye data iliyorudishwa na AuthService.login
      final role = result['data']['role'] ?? 'MEMBER';

      if (mounted) {
        // Angalia kama ni kiongozi/admin
        if (role == 'ADMIN' ||
            role == 'CHAIRPERSON' ||
            role == 'TREASURER' ||
            role == 'ACCOUNTANT' ||
            role == 'SECRETARY') {
          context.go('/admin');
        } else {
          context.go('/dashboard');
        }
      }
    } else {
      if (mounted) {
        _showError(result['message']);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('forgot_password_title'.tr(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('forgot_password_instructions'.tr(context)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'email'.tr(context),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context).toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final result = await AuthService.forgotPassword(email);

              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'],
                    ), // Keep this dynamic from backend
                    backgroundColor: result['success']
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('send_password_button'.tr(context).toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'app_name'.tr(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'app_tagline'.tr(context),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: LanguageService.instance.locale.languageCode,
                        icon: const Icon(Icons.language, color: Colors.white),
                        dropdownColor: AppTheme.primaryColor,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                            value: 'sw',
                            child: Text('Kiswahili'),
                          ),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            LanguageService.instance.changeLanguage(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'login'.tr(context),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(context),
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: 'hint_email'.tr(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'password'.tr(context),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : _showForgotPasswordDialog,
                          child: Text(
                            'forgot_password_prompt'.tr(context),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('login_button'.tr(context)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'no_account'.tr(context),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(
                              'register_link'.tr(context),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
