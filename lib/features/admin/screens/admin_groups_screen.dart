import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../services/admin_service.dart';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});

  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final groups = await AdminService.getAllGroups();
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }

  void _showGroupForm({Map<String, dynamic>? group}) {
    final nameController = TextEditingController(text: group?['name'] ?? '');
    final descController = TextEditingController(
      text: group?['description'] ?? '',
    );
    final contributionController = TextEditingController(
      text: group?['monthly_contribution']?.toString() ?? '',
    );
    final maxLoanController = TextEditingController(
      text: group?['max_loan_amount']?.toString() ?? '',
    );
    final interestController = TextEditingController(
      text: group?['interest_rate']?.toString() ?? '',
    );
    String selectedFrequency = group?['meeting_frequency'] ?? 'MONTHLY';

    final frequencies = ['WEEKLY', 'MONTHLY', 'QUARTERLY'];

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group == null ? 'Unda Kikundi Kipya' : 'Hariri Kikundi',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Jina la Kikundi',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Maelezo',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Mzunguko wa Mikutano',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: frequencies
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(_getFrequencyLabel(f)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedFrequency = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contributionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mchango wa Kila Mwezi (TZS)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxLoanController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mkopo wa Juu (TZS)',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: interestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Riba (%)',
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        contributionController.text.isEmpty ||
                        maxLoanController.text.isEmpty ||
                        interestController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tafadhali jaza sehemu zote'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    Map<String, dynamic> result;
                    if (group == null) {
                      result = await AdminService.createGroup(
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        meetingFrequency: selectedFrequency,
                        monthlyContribution: double.parse(
                          contributionController.text,
                        ),
                        maxLoanAmount: double.parse(maxLoanController.text),
                        interestRate: double.parse(interestController.text),
                      );
                    } else {
                      result = await AdminService.updateGroup(
                        groupId: group['id'] as int,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        meetingFrequency: selectedFrequency,
                        monthlyContribution: double.parse(
                          contributionController.text,
                        ),
                        maxLoanAmount: double.parse(maxLoanController.text),
                        interestRate: double.parse(interestController.text),
                      );
                    }
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
                  child: Text(
                    group == null ? 'UNDA KIKUNDI' : 'HIFADHI MABADILIKO',
                  ),
                ),
              ],
            ),
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
        title: const Text('Vikundi'),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupForm(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Kikundi Kipya',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _groups.isEmpty
                  ? const Center(
                      child: Text(
                        'Hakuna vikundi',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) =>
                          _buildGroupCard(_groups[index]),
                    ),
            ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final isActive = group['active'] == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF00897B)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Inafanya Kazi' : 'Imesimama',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (group['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      group['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _groupStat(
                      'Mchango',
                      'TZS ${_formatAmount(group['monthly_contribution'])}',
                    ),
                    _groupStat(
                      'Mkopo wa Juu',
                      'TZS ${_formatAmount(group['max_loan_amount'])}',
                    ),
                    _groupStat('Riba', '${group['interest_rate'] ?? 0}%'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mkutano: ${_getFrequencyLabel(group['meeting_frequency'] ?? '')}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showGroupForm(group: group),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      label: const Text(
                        'Hariri',
                        style: TextStyle(color: AppTheme.primaryColor),
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

  Widget _groupStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  String _getFrequencyLabel(String freq) {
    switch (freq) {
      case 'WEEKLY':
        return 'Kila Wiki';
      case 'MONTHLY':
        return 'Kila Mwezi';
      case 'QUARTERLY':
        return 'Kila Robo Mwaka';
      default:
        return freq;
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
