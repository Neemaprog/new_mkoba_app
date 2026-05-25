import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, String> _userInfo = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    final stats = await AdminService.getDashboardStats();
    setState(() {
      _userInfo = userInfo;
      _stats = stats;
      _isLoading = false;
    });
  }

  String get _role => _userInfo['role'] ?? 'ADMIN';

  // Angalia kama role ina ruhusa
  bool _canAccess(String feature) {
    switch (_role) {
      case 'ADMIN':
        return true;
      case 'CHAIRPERSON':
        return ['dashboard', 'members', 'loans', 'savings', 'reports', 'notifications'].contains(feature);
      case 'TREASURER':
        return ['dashboard', 'members', 'loans', 'savings', 'reports', 'notifications'].contains(feature);
      case 'ACCOUNTANT':
        return ['dashboard', 'members', 'loans', 'savings', 'reports'].contains(feature);
      case 'SECRETARY':
        return ['dashboard', 'members', 'loans', 'reports', 'notifications'].contains(feature);
      default:
        return false;
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
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 16),
                            if (_stats['pendingLoans'] > 0 ||
                                _stats['pendingConfirmation'] > 0)
                              _buildAlerts(),
                            const SizedBox(height: 16),
                            _buildMenuGrid(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
                  const Text('Karibu,',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    _userInfo['name'] ?? 'Admin',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleLabel(_role),
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat('Wanachama',
                  '${_stats['totalMembers'] ?? 0}', Icons.people),
              _headerStat('Akiba',
                  'TZS ${_formatAmount(_stats['totalSavings'])}',
                  Icons.savings),
              _headerStat('Mikopo Hai',
                  '${_stats['activeLoans'] ?? 0}', Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'Wanachama',
        'value': '${_stats['totalMembers'] ?? 0}',
        'icon': Icons.people_outlined,
        'color': AppTheme.primaryColor,
      },
      {
        'label': 'Jumla Akiba',
        'value': 'TZS ${_formatAmount(_stats['totalSavings'])}',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF00695C),
      },
      {
        'label': 'Mikopo Inayoendelea',
        'value': '${_stats['activeLoans'] ?? 0}',
        'icon': Icons.trending_up,
        'color': const Color(0xFF1565C0),
      },
      {
        'label': 'Inasubiri',
        'value': '${(_stats['pendingLoans'] ?? 0) + (_stats['pendingConfirmation'] ?? 0)}',
        'icon': Icons.pending_outlined,
        'color': const Color(0xFFE65100),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(stat['icon'] as IconData,
                    color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Text(
                    stat['label'] as String,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlerts() {
    return Column(
      children: [
        if ((_stats['pendingLoans'] ?? 0) > 0 &&
            (_role == 'CHAIRPERSON' || _role == 'ADMIN'))
          _buildAlertCard(
            '⚠️ Mikopo ${_stats['pendingLoans']} Inasubiri Idhini',
            'Inahitaji idhini yako',
            const Color(0xFFE65100),
            () => context.go('/admin/loans'),
          ),
        if ((_stats['pendingConfirmation'] ?? 0) > 0 &&
            (_role == 'TREASURER' || _role == 'ADMIN'))
          _buildAlertCard(
            '⚠️ Mikopo ${_stats['pendingConfirmation']} Inahitaji Uthibitisho',
            'Inahitaji uthibitisho wako',
            const Color(0xFF1565C0),
            () => context.go('/admin/loans'),
          ),
      ],
    );
  }

  Widget _buildAlertCard(
      String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final allMenus = [
      {
        'title': 'Wanachama',
        'icon': Icons.people_outlined,
        'color': AppTheme.primaryColor,
        'route': '/admin/members',
        'feature': 'members',
      },
      {
        'title': 'Mikopo',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF1565C0),
        'route': '/admin/loans',
        'feature': 'loans',
      },
      {
        'title': 'Akiba',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF00695C),
        'route': '/admin/savings',
        'feature': 'savings',
      },
      {
        'title': 'Ripoti',
        'icon': Icons.bar_chart_outlined,
        'color': const Color(0xFF6A1B9A),
        'route': '/admin/reports',
        'feature': 'reports',
      },
      {
        'title': 'Arifa',
        'icon': Icons.notifications_outlined,
        'color': const Color(0xFFE65100),
        'route': '/admin/notifications',
        'feature': 'notifications',
      },
      if (_role == 'ADMIN')
        {
          'title': 'Vikundi',
          'icon': Icons.group_work_outlined,
          'color': const Color(0xFF00838F),
          'route': '/admin/groups',
          'feature': 'groups',
        },
    ];

    final menus = allMenus
        .where((m) => _canAccess(m['feature'] as String))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Huduma za Usimamizi',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: menus.map((menu) {
            final color = menu['color'] as Color;
            return GestureDetector(
              onTap: () => context.go(menu['route'] as String),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      child: Icon(menu['icon'] as IconData,
                          color: color, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      menu['title'] as String,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondary,
      currentIndex: _selectedIndex,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashibodi'),
        BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Wanachama'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_balance),
            label: 'Mikopo'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Wasifu'),
      ],
      onTap: (index) {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0:
            context.go('/admin');
            break;
          case 1:
            context.go('/admin/members');
            break;
          case 2:
            context.go('/admin/loans');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN': return 'Msimamizi';
      case 'CHAIRPERSON': return 'Mwenyekiti';
      case 'TREASURER': return 'Mweka Hazina';
      case 'ACCOUNTANT': return 'Mhasibu';
      case 'SECRETARY': return 'Katibu';
      default: return role;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value =
        amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}