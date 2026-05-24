import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../loans_service.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _userId = 0;
  int _groupId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final loans = await LoansService.getUserLoans(_userId);
    setState(() {
      _loans = loans;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _activeLoans => _loans
      .where(
        (l) =>
            l['status'] == 'ACTIVE' ||
            l['status'] == 'PENDING' ||
            l['status'] == 'APPROVED',
      )
      .toList();

  List<Map<String, dynamic>> get _completedLoans =>
      _loans.where((l) => l['status'] == 'COMPLETED').toList();

  void _showApplyDialog() {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    final guarantorController = TextEditingController();

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
            const Text(
              'Omba Mkopo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kiasi (TZS)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(
                labelText: 'Madhumuni',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: guarantorController,
              decoration: const InputDecoration(
                labelText: 'Mdhamini (hiari)',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) return;
                Navigator.pop(context);
                final result = await LoansService.applyLoan(
                  userId: _userId,
                  groupId: _groupId,
                  amount: double.parse(amountController.text),
                  purpose: purposeController.text,
                  guarantor: guarantorController.text,
                );
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
                  if (result['success']) _loadData();
                }
              },
              child: const Text('TUMA MAOMBI'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepayDialog(Map<String, dynamic> loan) {
    final amountController = TextEditingController();

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
            const Text(
              'Lipa Mkopo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kilichobaki: TZS ${_formatAmount(loan['remaining_balance'])}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kiasi cha Kulipa (TZS)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) return;
                Navigator.pop(context);
                final result = await LoansService.repayLoan(
                  loanId: loan['id'] as int,
                  userId: _userId,
                  groupId: _groupId,
                  amount: double.parse(amountController.text),
                );
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
                  if (result['success']) _loadData();
                }
              },
              child: const Text('LIPA SASA'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mikopo Yangu'),
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
            Tab(text: 'Inayoendelea'),
            Tab(text: 'Iliyokamilika'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Omba Mkopo', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildList(_activeLoans), _buildList(_completedLoans)],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> loans) {
    if (loans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Hakuna mikopo hapa',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) => _buildLoanCard(loans[index]),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final isActive = loan['status'] == 'ACTIVE' || loan['status'] == 'PENDING';
    final double principal = (loan['amount'] ?? 0).toDouble();
    final double remaining = (loan['remaining_balance'] ?? 0).toDouble();
    final double progress = principal > 0
        ? (1 - (remaining / (loan['total_amount'] ?? principal)))
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mkopo #${loan['id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loan['status'] ?? '',
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('Kiasi', 'TZS ${_formatAmount(principal)}'),
              _stat('Kilichobaki', 'TZS ${_formatAmount(remaining)}'),
              _stat('Riba', '${loan['interest_rate'] ?? 0}%'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% imelipwa',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (isActive && loan['status'] == 'ACTIVE') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRepayDialog(loan),
                icon: const Icon(Icons.payment, color: AppTheme.primaryColor),
                label: const Text(
                  'Lipa Mkopo',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
