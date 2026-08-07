import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../../../features/savings/savings_service.dart';
import '../../../features/loans/loans_service.dart';
import '../../../features/notifications/notifications_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, String> _userInfo = {};
  double _totalSavings = 0.0;
  double _totalLoans = 0.0;
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userInfo = await AuthService.getUserInfo();
      _userId = int.tryParse(userInfo['id'] ?? '0') ?? 0;

      final savings = await SavingsService.getTotalSavings(_userId);
      final loans = await LoansService.getUserLoans(_userId);
      double totalLoans = 0;
      for (var loan in loans) {
        if (loan['status'] == 'ACTIVE') {
          totalLoans += (loan['remaining_balance'] ?? 0).toDouble();
        }
      }

      setState(() {
        _userInfo = userInfo;
        _totalSavings = savings;
        _totalLoans = totalLoans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : _buildContent(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'welcome_message'.tr(context),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    _userInfo['name'] ?? 'default_user'.tr(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTranslatedRole(_userInfo['role'] ?? 'MEMBER'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        FutureBuilder<int>(
                          future: NotificationsService.getUnreadCount(_userId),
                          builder: (context, snapshot) {
                            if ((snapshot.data ?? 0) == 0) {
                              return const SizedBox();
                            }
                            return Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text(
                  'total_savings_label'.tr(context),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'TZS ${_formatAmount(_totalSavings)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat(
                      'loans_label'.tr(context),
                      'TZS ${_formatAmount(_totalLoans)}',
                      Icons.trending_up,
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _miniStat(
                      'role_label'.tr(context),
                      _getTranslatedRole(_userInfo['role'] ?? 'MEMBER'),
                      Icons.person,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'services_title'.tr(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _menuCard(
                'savings_menu'.tr(context),
                Icons.savings_outlined,
                AppTheme.primaryColor,
                () => context.go('/savings'),
              ),
              _menuCard(
                'loans_menu'.tr(context),
                Icons.account_balance_outlined,
                const Color(0xFF1565C0),
                () => context.go('/loans'),
              ),
              _menuCard(
                'payments_menu'.tr(context),
                Icons.receipt_long_outlined,
                const Color(0xFF6A1B9A),
                () => context.go('/transactions'),
              ),
              _menuCard(
                'group_menu'.tr(context),
                Icons.group_outlined,
                const Color(0xFFE65100),
                () => context.go('/groups'),
              ),
              _menuCard(
                'reports_menu'.tr(context),
                Icons.bar_chart_outlined,
                const Color(0xFF00695C),
                () => context.go('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _menuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondary,
      currentIndex: 0,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'nav_home'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.savings_outlined),
          activeIcon: const Icon(Icons.savings),
          label: 'nav_savings'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_outlined),
          activeIcon: const Icon(Icons.account_balance),
          label: 'nav_loans'.tr(context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outlined),
          activeIcon: const Icon(Icons.person),
          label: 'nav_profile'.tr(context),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/savings');
            break;
          case 2:
            context.go('/loans');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num
        ? amount
        : num.tryParse(amount.toString()) ?? 0;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
