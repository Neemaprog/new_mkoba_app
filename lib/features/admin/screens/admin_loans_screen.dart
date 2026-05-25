import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../services/admin_service.dart';

class AdminLoansScreen extends StatefulWidget {
  const AdminLoansScreen({super.key});

  @override
  State<AdminLoansScreen> createState() => _AdminLoansScreenState();
}

class _AdminLoansScreenState extends State<AdminLoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allLoans = [];
  bool _isLoading = true;
  String _role = 'ADMIN';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    _role = userInfo['role'] ?? 'ADMIN';
    final loans = await AdminService.getAllLoans();
    setState(() {
      _allLoans = loans;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getByStatus(String status) {
    if (status == 'ALL') return _allLoans;
    return _allLoans.where((l) => l['status'] == status).toList();
  }

  // Angalia kama role inaweza kufanya action
  bool get _canApprove =>
      _role == 'CHAIRPERSON' || _role == 'ADMIN';
  bool get _canConfirm => _role == 'TREASURER';

  void _showActionDialog(
      Map<String, dynamic> loan, String action) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  action == 'approve'
                      ? Icons.check_circle_outline
                      : action == 'confirm'
                          ? Icons.verified_outlined
                          : Icons.cancel_outlined,
                  color: action == 'reject'
                      ? AppTheme.errorColor
                      : action == 'confirm'
                          ? const Color(0xFF1565C0)
                          : AppTheme.successColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  action == 'approve'
                      ? 'Idhinisha Mkopo'
                      : action == 'confirm'
                          ? 'Thibitisha Mkopo'
                          : 'Kataa Mkopo',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loan Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow('Mwombaji',
                      '${loan['first_name']} ${loan['last_name']}'),
                  const SizedBox(height: 8),
                  _infoRow('Kiasi',
                      'TZS ${_formatAmount(loan['amount'])}'),
                  const SizedBox(height: 8),
                  _infoRow('Madhumuni', loan['purpose'] ?? '-'),
                  if (loan['guarantor'] != null &&
                      loan['guarantor'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow('Mdhamini', loan['guarantor']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            Text(
              action == 'reject'
                  ? 'Sababu ya Kukataa (Inahitajika):'
                  : 'Maoni (Hiari):',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: action == 'reject'
                    ? 'Andika sababu ya kukataa...'
                    : 'Andika maoni yako...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ghairi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (action == 'reject' &&
                          reasonController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tafadhali andika sababu'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _performAction(
                          loan['id'] as int,
                          action,
                          reasonController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action == 'reject'
                          ? AppTheme.errorColor
                          : action == 'confirm'
                              ? const Color(0xFF1565C0)
                              : AppTheme.successColor,
                    ),
                    child: Text(
                      action == 'approve'
                          ? 'Idhinisha'
                          : action == 'confirm'
                              ? 'Thibitisha'
                              : 'Kataa',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction(
      int loanId, String action, String reason) async {
    Map<String, dynamic> result;

    if (action == 'approve') {
      result = await AdminService.approveLoan(loanId, reason);
    } else if (action == 'confirm') {
      result = await AdminService.confirmLoan(loanId, reason);
    } else {
      result = await AdminService.rejectLoan(loanId, reason);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success']
            ? AppTheme.successColor
            : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      if (result['success']) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Mikopo (${_allLoans.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: [
            Tab(text: 'Zote (${_allLoans.length})'),
            Tab(text: 'Zinasubiri (${_getByStatus('PENDING').length})'),
            Tab(text: 'Uthibitisho (${_getByStatus('PENDING_TREASURER_CONFIRMATION').length})'),
            Tab(text: 'Zinazoendelea (${_getByStatus('ACTIVE').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoansList(_getByStatus('ALL')),
                _buildLoansList(_getByStatus('PENDING')),
                _buildLoansList(
                    _getByStatus('PENDING_TREASURER_CONFIRMATION')),
                _buildLoansList(_getByStatus('ACTIVE')),
              ],
            ),
    );
  }

  Widget _buildLoansList(List<Map<String, dynamic>> loans) {
    if (loans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 80, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('Hakuna mikopo hapa',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) =>
            _buildLoanCard(loans[index]),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final status = loan['status'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      '${loan['first_name']?[0] ?? '?'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${loan['first_name']} ${loan['last_name']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),

          // Loan Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _loanStat('Kiasi',
                  'TZS ${_formatAmount(loan['amount'])}'),
              _loanStat('Jumla',
                  'TZS ${_formatAmount(loan['total_amount'])}'),
              _loanStat('Riba', '${loan['interest_rate'] ?? 0}%'),
            ],
          ),
          const SizedBox(height: 8),

          if (loan['purpose'] != null)
            Text(
              'Madhumuni: ${loan['purpose']}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              // CHAIRPERSON approve PENDING
              if (_canApprove && status == 'PENDING') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showActionDialog(loan, 'approve'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Idhinisha'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showActionDialog(loan, 'reject'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Kataa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],

              // TREASURER confirm PENDING_TREASURER_CONFIRMATION
              if (_canConfirm &&
                  status == 'PENDING_TREASURER_CONFIRMATION') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showActionDialog(loan, 'confirm'),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Thibitisha'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showActionDialog(loan, 'reject'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Kataa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],

              // Angalia tu kwa wengine
              if (status == 'ACTIVE' || status == 'COMPLETED' ||
                  status == 'REJECTED')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined,
                        size: 16),
                    label: const Text('Maelezo'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loanStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ],
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
      case 'PENDING_TREASURER_CONFIRMATION':
        color = const Color(0xFF1565C0);
        label = 'Uthibitisho';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value =
        amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}