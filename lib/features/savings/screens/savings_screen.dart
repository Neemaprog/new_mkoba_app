import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../savings_service.dart';
import '../../../core/services/azampay_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<Map<String, dynamic>> _savings = [];
  double _total = 0.0;
  bool _isLoading = true;
  int _userId = 0;
  int _groupId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    _userId = int.tryParse(userInfo['id'] ?? '0') ?? 0;
    _groupId = int.tryParse(userInfo['group_id'] ?? '1') ?? 1;
    final savings = await SavingsService.getUserSavings(_userId);
    final total = await SavingsService.getTotalSavings(_userId);
    setState(() {
      _savings = savings;
      _total = total;
      _isLoading = false;
    });
  }

  void _showAddSavingDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'MONTHLY_CONTRIBUTION';
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
                'Ongeza Akiba',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Kiasi
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kiasi (TZS)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'mfano: 50000',
                ),
              ),
              const SizedBox(height: 12),

              // Aina ya Akiba
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Aina ya Akiba',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MONTHLY_CONTRIBUTION',
                    child: Text('Mchango wa Kila Mwezi'),
                  ),
                  DropdownMenuItem(
                    value: 'ADDITIONAL_SAVINGS',
                    child: Text('Akiba ya Ziada'),
                  ),
                  DropdownMenuItem(value: 'PENALTY', child: Text('Faini')),
                  DropdownMenuItem(value: 'BONUS', child: Text('Bonasi')),
                ],
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              const SizedBox(height: 12),

              // Lipa kwa AzamPay toggle
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

              // Phone number (AzamPay)
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

              // Description
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Maelezo (hiari)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
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
                              content: Text('Weka kiasi'),
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
                          final azamResult =
                              await AzamPayService.contributeToSavings(
                                phoneNumber: phoneController.text.trim(),
                                amount: double.parse(amountController.text),
                                externalId: AzamPayService.generateExternalId(
                                  'SAV',
                                ),
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
                        final result = await SavingsService.addSaving(
                          userId: _userId,
                          groupId: _groupId,
                          amount: double.parse(amountController.text),
                          type: selectedType,
                          description: descController.text.isNotEmpty
                              ? descController.text
                              : useAzamPay
                              ? 'Mchango kwa AzamPay'
                              : 'Mchango wa akiba',
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
                    : Text(useAzamPay ? 'LIPA KWA AZAMPAY' : 'HIFADHI AKIBA'),
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
        title: const Text('Akiba Zangu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSavingDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ongeza', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Total Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Jumla ya Akiba',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TZS ${_formatAmount(_total)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Michango ${_savings.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_savings.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 80,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Hakuna akiba bado',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _savings[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.savings_outlined,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s['description'] ?? 'Akiba',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        s['contribution_date']
                                                ?.toString()
                                                .substring(0, 10) ??
                                            '',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'TZS ${_formatAmount(s['amount'])}',
                                  style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
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
