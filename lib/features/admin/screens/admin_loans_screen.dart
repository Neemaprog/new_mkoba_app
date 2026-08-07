import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_service.dart';
import '../services/admin_service.dart';
import 'loan_details_screen.dart';

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
  bool get _canApprove => _role == 'TREASURER';
  bool get _canConfirm => _role == 'CHAIRPERSON' || _role == 'ADMIN';

  void _showActionDialog(Map<String, dynamic> loan, String action) {
    final reasonController = TextEditingController();

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
                      ? 'approve_loan_title'.tr(context)
                      : action == 'confirm'
                      ? 'confirm_loan_title'.tr(context)
                      : 'reject_loan_title'.tr(context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  _infoRow(
                    'applicant'.tr(context),
                    '${loan['first_name']} ${loan['last_name']}',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'amount_label'.tr(context),
                    'TZS ${_formatAmount(loan['amount'])}',
                  ),
                  const SizedBox(height: 8),
                  _infoRow('purpose_label'.tr(context), loan['purpose'] ?? '-'),
                  if (loan['guarantor'] != null &&
                      loan['guarantor'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow(
                      'guarantor_label_optional'.tr(context),
                      loan['guarantor'],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            Text(
              action == 'reject'
                  ? 'rejection_reason_required'.tr(context)
                  : 'comments_optional'.tr(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: action == 'reject'
                    ? 'rejection_reason_hint'.tr(context)
                    : 'comments_hint'.tr(context),
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
                    child: Text('cancel'.tr(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (action == 'reject' && reasonController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('write_reason_prompt'.tr(context)),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _performAction(
                        loan['id'] as int,
                        action,
                        reasonController.text,
                      );
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
                          ? 'approve'.tr(context)
                          : action == 'confirm'
                          ? 'confirm_loan'.tr(context)
                          : 'reject'.tr(context),
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

  Future<void> _performAction(int loanId, String action, String reason) async {
    Map<String, dynamic> result;

    if (action == 'approve') {
      result = await AdminService.approveLoan(loanId, reason);
    } else if (action == 'confirm') {
      result = await AdminService.confirmLoan(loanId, reason);
    } else {
      result = await AdminService.rejectLoan(loanId, reason);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['message'] as String).tr(context)),
          backgroundColor: result['success']
              ? AppTheme.successColor
              : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result['success']) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('${'loans'.tr(context)} (${_allLoans.length})'),
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
            Tab(text: '${'all_filter'.tr(context)} (${_allLoans.length})'),
            Tab(
              text:
                  '${'pending'.tr(context)} (${_getByStatus('PENDING').length})',
            ),
            Tab(
              text:
                  '${'status_confirmation'.tr(context)} (${_getByStatus('PENDING_ADMIN_CONFIRMATION').length})',
            ),
            Tab(
              text:
                  '${'ongoing'.tr(context)} (${_getByStatus('ACTIVE').length})',
            ),
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
                _buildLoansList(_getByStatus('ALL')),
                _buildLoansList(_getByStatus('PENDING')),
                _buildLoansList(_getByStatus('PENDING_ADMIN_CONFIRMATION')),
                _buildLoansList(_getByStatus('ACTIVE')),
              ],
            ),
    );
  }

  Widget _buildLoansList(List<Map<String, dynamic>> loans) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'no_loans_message'.tr(context),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
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
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${loan['first_name']} ${loan['last_name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
              _loanStat(
                'principal_label'.tr(context),
                'TZS ${_formatAmount(loan['amount'])}',
              ),
              _loanStat(
                'total'.tr(context),
                'TZS ${_formatAmount(loan['total_amount'])}',
              ),
              _loanStat(
                'interest_rate'.tr(context),
                '${loan['interest_rate'] ?? 0}%',
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (loan['purpose'] != null)
            Text(
              '${'purpose'.tr(context)}: ${loan['purpose']}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              // TREASURER approve PENDING
              if (_canApprove && status == 'PENDING') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActionDialog(loan, 'approve'),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('approve'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActionDialog(loan, 'reject'),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('reject'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],

              // ADMIN/CHAIRPERSON confirm PENDING_ADMIN_CONFIRMATION
              if (_canConfirm && status == 'PENDING_ADMIN_CONFIRMATION') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActionDialog(loan, 'confirm'),
                    icon: const Icon(Icons.verified, size: 16),
                    label: Text('confirm_loan'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showActionDialog(loan, 'reject'),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('reject'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],

              // Angalia tu kwa wengine
              if (status == 'ACTIVE' ||
                  status == 'COMPLETED' ||
                  status == 'REJECTED')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoanDetailsScreen(loanId: loan['id'] as int),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text('details'.tr(context)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
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
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = const Color(0xFFE65100);
        label = 'status_pending'.tr(context);
        break;
      case 'PENDING_ADMIN_CONFIRMATION':
        color = const Color(0xFF1565C0);
        label = 'status_confirmation'.tr(context);
        break;
      case 'ACTIVE':
        color = AppTheme.successColor;
        label = 'status_ongoing'.tr(context);
        break;
      case 'COMPLETED':
        color = AppTheme.textSecondary;
        label = 'status_completed'.tr(context);
        break;
      case 'REJECTED':
        color = AppTheme.errorColor;
        label = 'status_rejected'.tr(context);
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
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
