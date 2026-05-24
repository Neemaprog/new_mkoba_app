import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../../../core/database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  int _userId = 0;
  int _groupId = 1;

  // Savings data
  double _totalSavings = 0;
  List<Map<String, dynamic>> _monthlySavings = [];

  // Loans data
  double _totalLoans = 0;
  double _totalPaid = 0;
  double _totalRemaining = 0;
  int _activeLoans = 0;
  int _completedLoans = 0;

  // Transactions data
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
    final userInfo = await AuthService.getUserInfo();
    _userId = int.tryParse(userInfo['id'] ?? '0') ?? 0;
    _groupId = int.tryParse(userInfo['group_id'] ?? '1') ?? 1;

    final db = await DatabaseHelper.instance.database;

    // Savings
    final savingsResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM savings WHERE user_id = ?',
      [_userId],
    );
    _totalSavings = (savingsResult.first['total'] as double?) ?? 0.0;

    // Monthly savings (last 6 months)
    final monthlySavings = await db.rawQuery(
      '''
      SELECT 
        strftime('%m', contribution_date) as month,
        strftime('%Y', contribution_date) as year,
        SUM(amount) as total
      FROM savings 
      WHERE user_id = ?
      AND contribution_date >= date('now', '-6 months')
      GROUP BY strftime('%Y-%m', contribution_date)
      ORDER BY year, month
    ''',
      [_userId],
    );
    _monthlySavings = monthlySavings;

    // Loans
    final loansResult = await db.rawQuery(
      '''
      SELECT 
        SUM(total_amount) as total,
        SUM(amount_paid) as paid,
        SUM(remaining_balance) as remaining,
        COUNT(CASE WHEN status = 'ACTIVE' OR status = 'PENDING' THEN 1 END) as active,
        COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed
      FROM loans WHERE user_id = ?
    ''',
      [_userId],
    );

    if (loansResult.isNotEmpty) {
      _totalLoans = (loansResult.first['total'] as double?) ?? 0.0;
      _totalPaid = (loansResult.first['paid'] as double?) ?? 0.0;
      _totalRemaining = (loansResult.first['remaining'] as double?) ?? 0.0;
      _activeLoans = (loansResult.first['active'] as int?) ?? 0;
      _completedLoans = (loansResult.first['completed'] as int?) ?? 0;
    }

    // Recent transactions
    final transactions = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [_userId],
      orderBy: 'transaction_date DESC',
      limit: 10,
    );
    _recentTransactions = transactions;

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ripoti Zangu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Akiba'),
            Tab(text: 'Mikopo'),
            Tab(text: 'Muhtasari'),
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
                _buildSavingsTab(),
                _buildLoansTab(),
                _buildSummaryTab(),
              ],
            ),
    );
  }

  // ===================== SAVINGS TAB =====================
  Widget _buildSavingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Card
          _buildStatCard(
            title: 'Jumla ya Akiba Yako',
            value: 'TZS ${_formatAmount(_totalSavings)}',
            icon: Icons.savings_outlined,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),

          // Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akiba kwa Miezi 6 Iliyopita',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _monthlySavings.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Hakuna data ya kutosha',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                _monthlySavings
                                    .map((e) => (e['total'] as double?) ?? 0.0)
                                    .fold(0.0, (a, b) => a > b ? a : b) *
                                1.2,
                            barGroups: _monthlySavings
                                .asMap()
                                .entries
                                .map(
                                  (entry) => BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY:
                                            (entry.value['total'] as double?) ??
                                            0.0,
                                        color: AppTheme.primaryColor,
                                        width: 20,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final months = [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug',
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec',
                                    ];
                                    final idx = value.toInt();
                                    if (idx < _monthlySavings.length) {
                                      final month =
                                          int.tryParse(
                                            _monthlySavings[idx]['month']
                                                .toString(),
                                          ) ??
                                          1;
                                      return Text(
                                        months[month - 1],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== LOANS TAB =====================
  Widget _buildLoansTab() {
    final total = _totalLoans > 0 ? _totalLoans : 1;
    final paidPercent = _totalPaid / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Mikopo Inayoendelea',
                  value: '$_activeLoans',
                  icon: Icons.pending_outlined,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Iliyokamilika',
                  value: '$_completedLoans',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pie Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hali ya Mikopo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _totalLoans == 0
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Hakuna mikopo bado',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: _totalPaid,
                                    color: AppTheme.successColor,
                                    title:
                                        '${(paidPercent * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    radius: 60,
                                  ),
                                  PieChartSectionData(
                                    value: _totalRemaining,
                                    color: AppTheme.errorColor,
                                    title:
                                        '${((1 - paidPercent) * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    radius: 60,
                                  ),
                                ],
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _legend(
                                  'Imelipwa',
                                  'TZS ${_formatAmount(_totalPaid)}',
                                  AppTheme.successColor,
                                ),
                                const SizedBox(height: 12),
                                _legend(
                                  'Kilichobaki',
                                  'TZS ${_formatAmount(_totalRemaining)}',
                                  AppTheme.errorColor,
                                ),
                                const SizedBox(height: 12),
                                _legend(
                                  'Jumla',
                                  'TZS ${_formatAmount(_totalLoans)}',
                                  AppTheme.primaryColor,
                                ),
                              ],
                            ),
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

  // ===================== SUMMARY TAB =====================
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Akiba Yote',
                  value: 'TZS ${_formatAmount(_totalSavings)}',
                  icon: Icons.savings_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Madeni',
                  value: 'TZS ${_formatAmount(_totalRemaining)}',
                  icon: Icons.account_balance_outlined,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Transactions
          const Text(
            'Malipo ya Hivi Karibuni',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _recentTransactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Hakuna malipo bado',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = _recentTransactions[index];
                    final type = t['type']?.toString() ?? '';
                    final isCredit =
                        type.contains('SAVINGS') ||
                        type.contains('DISBURSEMENT');
                    return Container(
                      padding: const EdgeInsets.all(12),
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
                              isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
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
                                  t['description'] ?? type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  t['transaction_date']?.toString().substring(
                                        0,
                                        10,
                                      ) ??
                                      '',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
