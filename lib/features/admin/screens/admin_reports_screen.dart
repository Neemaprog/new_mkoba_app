import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';
import '../../../core/database/database_helper.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _topSavers = [];
  List<Map<String, dynamic>> _recentLoans = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await AdminService.getDashboardStats();
    final db = await DatabaseHelper.instance.database;

    // Top savers
    final topSavers = await db.rawQuery('''
      SELECT u.first_name, u.last_name, SUM(s.amount) as total
      FROM savings s
      LEFT JOIN users u ON s.user_id = u.id
      GROUP BY s.user_id
      ORDER BY total DESC
      LIMIT 5
    ''');

    // Recent loans
    final recentLoans = await db.rawQuery('''
      SELECT l.*, u.first_name, u.last_name
      FROM loans l
      LEFT JOIN users u ON l.user_id = u.id
      ORDER BY l.created_at DESC
      LIMIT 10
    ''');

    // Recent transactions
    final recentTransactions = await db.rawQuery('''
      SELECT t.*, u.first_name, u.last_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      ORDER BY t.transaction_date DESC
      LIMIT 10
    ''');

    setState(() {
      _stats = stats;
      _topSavers = topSavers;
      _recentLoans = recentLoans;
      _recentTransactions = recentTransactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ripoti za Kikundi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/admin'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Muhtasari'),
            Tab(text: 'Akiba'),
            Tab(text: 'Malipo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildSavingsTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _statCard(
                'Wanachama',
                '${_stats['totalMembers'] ?? 0}',
                Icons.people_outlined,
                AppTheme.primaryColor,
              ),
              _statCard(
                'Jumla Akiba',
                'TZS ${_formatAmount(_stats['totalSavings'])}',
                Icons.savings_outlined,
                const Color(0xFF00695C),
              ),
              _statCard(
                'Mikopo Hai',
                '${_stats['activeLoans'] ?? 0}',
                Icons.account_balance_outlined,
                const Color(0xFF1565C0),
              ),
              _statCard(
                'Jumla Mikopo',
                'TZS ${_formatAmount(_stats['totalLoans'])}',
                Icons.trending_up,
                const Color(0xFFE65100),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Loans
          _sectionTitle('Mikopo ya Hivi Karibuni'),
          const SizedBox(height: 12),
          ..._recentLoans
              .take(5)
              .map(
                (loan) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loan['first_name']} ${loan['last_name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            loan['purpose'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TZS ${_formatAmount(loan['amount'])}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          _statusBadge(loan['status'] ?? ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSavingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Jumla ya Akiba',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'TZS ${_formatAmount(_stats['totalSavings'])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Top Savers
          _sectionTitle('Wanaochanga Zaidi'),
          const SizedBox(height: 12),
          ..._topSavers.asMap().entries.map((entry) {
            final index = entry.key;
            final saver = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppTheme.accentColor
                          : index == 1
                          ? Colors.grey[300]
                          : Colors.brown[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${saver['first_name']} ${saver['last_name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'TZS ${_formatAmount(saver['total'])}',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _recentTransactions.isEmpty
          ? const Center(
              child: Text(
                'Hakuna malipo',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentTransactions.length,
              itemBuilder: (context, index) {
                final t = _recentTransactions[index];
                final type = t['type']?.toString() ?? '';
                final isCredit =
                    type.contains('SAVINGS') || type.contains('DISBURSEMENT');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? AppTheme.successColor.withValues(alpha: 0.1)
                              : AppTheme.errorColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t['first_name']} ${t['last_name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              t['description'] ?? type,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : '-'} TZS ${_formatAmount(t['amount'])}',
                        style: TextStyle(
                          color: isCredit
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
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
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = const Color(0xFFE65100);
        label = 'Inasubiri';
        break;
      case 'ACTIVE':
        color = AppTheme.successColor;
        label = 'Inayoendelea';
        break;
      case 'COMPLETED':
        color = AppTheme.textSecondary;
        label = 'Imekamilika';
        break;
      case 'REJECTED':
        color = AppTheme.errorColor;
        label = 'Imekataliwa';
        break;
      default:
        color = AppTheme.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
