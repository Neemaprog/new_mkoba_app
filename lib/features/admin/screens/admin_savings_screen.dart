import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class AdminSavingsScreen extends StatefulWidget {
  const AdminSavingsScreen({super.key});

  @override
  State<AdminSavingsScreen> createState() => _AdminSavingsScreenState();
}

class _AdminSavingsScreenState extends State<AdminSavingsScreen> {
  List<Map<String, dynamic>> _savings = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  double _totalSavings = 0.0;

  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final savings = await AdminService.getAllSavings();
    double total = 0;
    for (var s in savings) {
      total += (s['amount'] as num? ?? 0).toDouble();
    }
    setState(() {
      _savings = savings;
      _filtered = savings;
      _totalSavings = total;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _savings;
      } else {
        _filtered = _savings.where((s) {
          final name = '${s['first_name']} ${s['last_name']}'.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);

    final result = await AdminService.generateSavingsCSV();

    if (mounted) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: result['success']
              ? AppTheme.successColor
              : AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('savings_all_groups'.tr(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadReport,
          ),
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
          : Stack(
              children: [
                Column(
                  children: [
                    // Total Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
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
                          Text(
                            'total_savings_all_groups'.tr(context),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TZS ${_formatAmount(_totalSavings)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'contributions'.tr(context)}: ${_savings.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: 'search_member_hint'.tr(context),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'no_savings_found'.tr(context),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildCard(_filtered[index]),
                              ),
                            ),
                    ),
                  ],
                ),
                if (_isDownloading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Downloading report...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> saving) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              '${saving['first_name']?[0] ?? '?'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${saving['first_name']} ${saving['last_name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  saving['description'] ?? 'savings_contribution'.tr(context),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  saving['contribution_date']?.toString().substring(0, 10) ??
                      '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${'group'.tr(context)}: ${saving['group_name'] ?? '-'}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${_formatAmount(saving['amount'])}',
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getSavingTypeLabel(saving['type'] ?? ''),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSavingTypeLabel(String type) {
    switch (type) {
      case 'MONTHLY_CONTRIBUTION':
        return 'monthly_contribution_option'.tr(context);
      case 'ADDITIONAL_SAVINGS':
        return 'additional_savings_option'.tr(context);
      case 'PENALTY':
        return 'penalty_option'.tr(context);
      case 'BONUS':
        return 'bonus_option'.tr(context);
      default:
        return type;
    }
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
