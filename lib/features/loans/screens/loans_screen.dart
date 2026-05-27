import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../loans_service.dart';
import '../../../core/services/azampay_service.dart';

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
    final phoneController = TextEditingController();
    bool useAzamPay = true;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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

              // Loan Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kilichobaki:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      'TZS ${_formatAmount(loan['remaining_balance'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kiasi
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kiasi cha Kulipa (TZS)',
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: 'Max: ${_formatAmount(loan['remaining_balance'])}',
                ),
              ),
              const SizedBox(height: 12),

              // AzamPay Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.network(
                          'https://azampay.co.tz/wp-content/uploads/2021/09/azampay-logo.png',
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.payment,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lipa kwa AzamPay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: useAzamPay,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setModalState(() => useAzamPay = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              if (useAzamPay)
                Column(
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nambari ya Simu',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '0712345678',
                        helperText: 'Airtel, Tigo, Mpesa, Halopesa',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Utapata ujumbe kwenye simu yako kuthibitisha malipo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Button
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weka kiasi cha kulipa'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        final remaining =
                            (loan['remaining_balance'] as double? ?? 0);

                        if (amount > remaining) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kiasi kikubwa kuliko kilichobaki!',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        if (useAzamPay && phoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weka nambari ya simu'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }

                        setModalState(() => isProcessing = true);

                        if (useAzamPay) {
                          // Lipa kwa AzamPay
                          final azamResult = await AzamPayService.repayLoan(
                            phoneNumber: phoneController.text.trim(),
                            amount: amount,
                            loanId: loan['id'].toString(),
                          );

                          if (!azamResult['success']) {
                            setModalState(() => isProcessing = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(azamResult['message']),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }
                        }

                        // Hifadhi kwenye database
                        Navigator.pop(context);
                        final result = await LoansService.repayLoan(
                          loanId: loan['id'] as int,
                          userId: _userId,
                          groupId: _groupId,
                          amount: amount,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                useAzamPay
                                    ? '✅ Malipo yametumwa! ${result['message']}'
                                    : result['message'],
                              ),
                              backgroundColor: result['success']
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (result['success']) _loadData();
                        }
                      },
                child: isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Inatuma ombi...'),
                        ],
                      )
                    : Text(useAzamPay ? 'LIPA KWA AZAMPAY' : 'LIPA MKOPO'),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
