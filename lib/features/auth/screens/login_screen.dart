import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      _showError('Tafadhali jaza email na password');
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
        title: const Text('Umesahau Nywila?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Weka email uliyotumia kujisajili. Tutakutumia nywila mpya.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GHAIRI'),
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
                    content: Text(result['message']),
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
            child: const Text('TUMA NYWILA'),
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
                  const Text(
                    'Mkoba System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mfumo wa Akiba na Mikopo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      const Text(
                        'Ingia',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'mfano@email.com',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Nywila',
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
                          child: const Text(
                            'Umesahau Nywila?',
                            style: TextStyle(color: AppTheme.primaryColor),
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
                            : const Text('INGIA'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Huna akaunti? ',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              'Jisajili',
                              style: TextStyle(
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
