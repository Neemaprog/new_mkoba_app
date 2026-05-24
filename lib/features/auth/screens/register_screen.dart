import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String _selectedRole = 'MEMBER';
  int? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];

  final List<String> _roles = [
    'MEMBER',
    'ADMIN',
    'ACCOUNTANT',
    'CHAIRPERSON',
    'SECRETARY',
    'TREASURER',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final db = await DatabaseHelper.instance.database;
    final groups = await db.query('groups', where: 'active = ?', whereArgs: [1]);
    setState(() {
      _groups = groups;
      if (groups.isNotEmpty) {
        _selectedGroupId = groups.first['id'] as int;
      }
    });
  }

  Future<void> _register() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Tafadhali jaza sehemu zote', isError: true);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Nywila hazifanani', isError: true);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showMessage('Nywila lazima iwe na herufi 6 au zaidi', isError: true);
      return;
    }
    if (_selectedGroupId == null) {
      _showMessage('Tafadhali chagua kikundi', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      groupId: _selectedGroupId!,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showMessage('Umesajiliwa! Tafadhali ingia', isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    } else {
      if (mounted) _showMessage(result['message'], isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jisajili',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      Text('Tengeneza akaunti yako',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Jina la Kwanza
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Jina la Kwanza',
                          prefixIcon: Icon(Icons.person_outlined),
                          hintText: 'mfano: John',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Jina la Ukoo
                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Jina la Ukoo',
                          prefixIcon: Icon(Icons.person_outlined),
                          hintText: 'mfano: Doe',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'mfano@email.com',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Simu
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nambari ya Simu',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '0712345678',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chagua Kikundi
                      DropdownButtonFormField<int>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Chagua Kikundi',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        items: _groups.map((group) {
                          return DropdownMenuItem<int>(
                            value: group['id'] as int,
                            child: Text(group['name'] as String),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedGroupId = val),
                      ),
                      const SizedBox(height: 12),

                      // Chagua Jukumu
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Jukumu',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(_getRoleLabel(role)),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                      ),
                      const SizedBox(height: 12),

                      // Nywila
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Nywila',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Thibitisha Nywila
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Thibitisha Nywila',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('JISAJILI'),
                      ),
                      const SizedBox(height: 16),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Una akaunti tayari? ',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text('Ingia',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN': return 'Msimamizi';
      case 'ACCOUNTANT': return 'Mhasibu';
      case 'CHAIRPERSON': return 'Mwenyekiti';
      case 'SECRETARY': return 'Katibu';
      case 'TREASURER': return 'Mweka Hazina';
      default: return 'Mwanachama';
    }
  }
}