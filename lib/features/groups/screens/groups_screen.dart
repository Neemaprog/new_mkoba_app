import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../groups_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  Map<String, dynamic> _group = {};
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  int _groupId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    _groupId = int.tryParse(userInfo['group_id'] ?? '1') ?? 1;

    final group = await GroupsService.getUserGroup(_groupId);
    final summary = await GroupsService.getGroupSummary(_groupId);
    final members = await GroupsService.getGroupMembers(_groupId);

    setState(() {
      _group = group ?? {};
      _summary = summary;
      _members = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('my_group_title'.tr(context)),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Info Card
                    _buildGroupCard(),
                    const SizedBox(height: 20),

                    // Summary Cards
                    _buildSummaryRow(),
                    const SizedBox(height: 24),

                    // Members
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'members'.tr(context),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_members.length} ${'people'.tr(context)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _members.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'no_members_yet'.tr(context),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                _buildMemberCard(_members[index]),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGroupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _group['name'] ?? 'my_group_title'.tr(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_group['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _group['description'],
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _groupStat(
                'meeting_label'.tr(context),
                _group['meeting_frequency'] ?? '-',
              ),
              _groupStat(
                'contribution_label'.tr(context),
                'TZS ${_formatAmount(_group['monthly_contribution'])}',
              ),
              _groupStat(
                'interest_rate_label'.tr(context),
                '${_group['interest_rate'] ?? 0}%',
              ),
            ],
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label.tr(context),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'total_savings_label'.tr(context),
            'TZS ${_formatAmount(_summary['totalSavings'])}',
            Icons.savings_outlined,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'loans_label'.tr(context),
            'TZS ${_formatAmount(_summary['totalLoans'])}',
            Icons.account_balance_outlined,
            const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'members_label'.tr(context),
            '${_summary['memberCount'] ?? 0}',
            Icons.people_outlined,
            const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label.tr(context),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name =
        '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    final role = member['role'] ?? 'MEMBER';

    return Container(
      padding: const EdgeInsets.all(12),
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
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              initial,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  member['phone_number'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleLabel(role),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'role_admin'.tr(context);
      case 'CHAIRPERSON':
        return 'role_chairperson'.tr(context);
      case 'TREASURER':
        return 'role_treasurer'.tr(context);
      case 'ACCOUNTANT':
        return 'role_accountant'.tr(context);
      case 'SECRETARY':
        return 'role_secretary'.tr(context);
      default:
        return 'role_member'.tr(context);
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value =
        amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
