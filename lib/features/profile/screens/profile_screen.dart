import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String> _userInfo = {};
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final info = await AuthService.getUserInfo();
    setState(() {
      _userInfo = info;
      final nameParts = (info['name'] ?? '').split(' ');
      _firstNameController.text = nameParts.first;
      _lastNameController.text = nameParts.length > 1 ? nameParts.last : '';
      _phoneController.text = info['phone'] ?? '';
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_firstNameController.text.isEmpty) {
      _showMessage('enter_your_name_prompt'.tr(context), isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final userId = int.tryParse(_userInfo['id'] ?? '0') ?? 0;
    final result = await AuthService.updateProfile(
      userId: userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      _showMessage(
        result['success']
            ? 'profile_updated_success'.tr(context)
            : result['message'],
        isError: !result['success'],
      );
      if (result['success']) _loadUserInfo();
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showMessage('fill_all_fields_prompt'.tr(context), isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('passwords_do_not_match_prompt'.tr(context), isError: true);
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showMessage('password_length_prompt'.tr(context), isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final userId = int.tryParse(_userInfo['id'] ?? '0') ?? 0;
    final result = await AuthService.changePassword(
      userId: userId,
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      _showMessage(
        result['success']
            ? 'password_changed_success'.tr(context)
            : result['message'],
        isError: !result['success'],
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout_title'.tr(context)),
        content: Text('logout_confirmation'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no_button'.tr(context)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text('yes_logout_button'.tr(context)),
          ),
        ],
      ),
    );
  }

  String _getTranslatedRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'role_admin'.tr(context);
      case 'CHAIRPERSON':
        return 'role_chairperson'.tr(context);
      case 'TREASURER':
        return 'role_treasurer'.tr(context);
      case 'ACCOUNTANT':
        return 'role_accountant'.tr(context);
      case 'SECRETARY':
        return 'role_secretary'.tr(context);
      case 'MEMBER':
        return 'role_member'.tr(context);
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('profile_title'.tr(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      (_userInfo['name'] ?? 'M')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userInfo['name'] ?? 'default_user'.tr(context),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userInfo['email'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userInfo['phone'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTranslatedRole(_userInfo['role'] ?? 'MEMBER'),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _menuItem(
                    icon: Icons.edit_outlined,
                    title: 'edit_profile_menu'.tr(context),
                    subtitle: 'edit_profile_subtitle'.tr(context),
                    onTap: _showUpdateProfileSheet,
                  ),
                  const Divider(height: 1, indent: 56),
                  _menuItem(
                    icon: Icons.lock_outlined,
                    title: 'change_password_menu'.tr(context),
                    subtitle: 'change_password_subtitle'.tr(context),
                    onTap: _showChangePasswordSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text('logout_button'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showUpdateProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'edit_profile_title'.tr(context),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'first_name'.tr(context),
                prefixIcon: const Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'last_name'.tr(context),
                prefixIcon: const Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'phone_number'.tr(context),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('save_changes_button'.tr(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'change_password_title'.tr(context),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'current_password'.tr(context),
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'new_password'.tr(context),
                prefixIcon: const Icon(Icons.lock_open_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'confirm_new_password'.tr(context),
                prefixIcon: const Icon(Icons.lock_open_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('change_button'.tr(context)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
