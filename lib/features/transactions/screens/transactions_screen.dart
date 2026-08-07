import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../transactions_service.dart';



class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _selectedFilter = 'all_filter';
  int _userId = 0;

  final List<String> _filters = [
  'all_filter',
  'savings_filter',
  'loan_filter',
  'payment_filter',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    _userId = int.tryParse(userInfo['id'] ?? '0') ?? 0;
    final transactions = await TransactionsService.getUserTransactions(_userId);
    setState(() {
      _transactions = transactions;
      _filtered = transactions;
      _isLoading = false;
    });
  }

  void _applyFilter(String filter) {
   setState(() {
    _selectedFilter = filter;
    if (filter == 'all_filter') {
      _filtered = _transactions;
    } else {
      final Map<String, List<String>> filterMap = {
        'savings_filter': ['SAVINGS_CONTRIBUTION'],
        'loan_filter': ['LOAN_DISBURSEMENT'],
        'payment_filter': ['LOAN_REPAYMENT', 'PENALTY_PAYMENT', 'FEE'],
      };
      final types = filterMap[filter] ?? [];
      _filtered = _transactions
          .where((t) => types.contains(t['type']))
          .toList();
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
  title: Text('transaction_history_title'.tr(context)),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
    onPressed: () => context.go('/dashboard'),
  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _applyFilter(filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                filter.tr(context),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'no_transactions'.tr(context),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) =>
                                _buildCard(_filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final type = (t['type'] ?? '').toString();
    final isCredit = type.contains('SAVINGS') || type.contains('DISBURSEMENT');
    final color = isCredit ? AppTheme.successColor : AppTheme.errorColor;

    IconData icon;
    String label;
    if (type.contains('SAVINGS')) {
      icon = Icons.savings_outlined;
      label = 'savings_contribution_label'.tr(context);
    } else if (type.contains('DISBURSEMENT')) {
      icon = Icons.account_balance_outlined;
      label = 'loan_disbursement_label'.tr(context);
    } else if (type.contains('REPAYMENT')) {
      icon = Icons.payment_outlined;
      label = 'loan_repayment_label'.tr(context);
    } else {
      icon = Icons.swap_horiz;
      label = 'payment_label'.tr(context);
    }

    String description = t['description'] ?? '';
    if (description.toLowerCase() == 'savings contribution') {
      description = 'savings_contribution_label'.tr(context);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t['transaction_date']?.toString().substring(0, 10) ?? '',
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
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
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