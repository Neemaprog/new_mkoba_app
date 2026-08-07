import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../services/admin_service.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _role = 'ADMIN';

  final List<String> _roles = [
    'role_member',
    'role_chairperson',
    'role_treasurer',
    'role_accountant',
    'role_secretary',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    _role = userInfo['role'] ?? 'ADMIN';
    final members = await AdminService.getAllMembers();
    setState(() {
      _members = members.where((m) => m['role'] != 'ADMIN').toList();
      _filtered = _members;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtered = _members;
      } else {
        _filtered = _members.where((m) {
          final name = '${m['first_name']} ${m['last_name']}'.toLowerCase();
          final phone = (m['phone_number'] ?? '').toLowerCase();
          final email = (m['email'] ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              phone.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar na Jina
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        '${member['first_name'][0]}${member['last_name'][0]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${member['first_name']} ${member['last_name']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _roleBadge(member['role'] ?? 'role_member'.tr(context)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Maelezo
              _detailRow(
                Icons.email_outlined,
                'email'.tr(context),
                member['email'] ?? '',
              ),
              _detailRow(
                Icons.phone_outlined,
                'phone'.tr(context),
                member['phone_number'] ?? '',
              ),
              _detailRow(
                Icons.group_outlined,
                'group'.tr(context),
                member['group_name'] ?? '-',
              ),
              _detailRow(
                Icons.circle,
                'status'.tr(context),
                member['status'] == 'ACTIVE'
                    ? 'active'.tr(context)
                    : 'inactive'.tr(context),
              ),
              const SizedBox(height: 20),

              // Actions — ADMIN/SECRETARY wanaweza kubadilisha
              if (_role == 'ADMIN' || _role == 'SECRETARY') ...[
                Text(
                  'actions'.tr(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Badilisha Role
                DropdownButtonFormField<String>(
                  initialValue: 'role_${member['role']?.toLowerCase()}',
                  decoration: InputDecoration(
                    labelText: 'change_role'.tr(context),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  items: _roles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.tr(context)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      Navigator.pop(context);
                      final result = await AdminService.updateMemberRole(
                        member['id'] as int,
                        val.split('_').last.toUpperCase(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['success'] == true
                                  ? 'role_changed_success'.tr(context)
                                  : (result['message'] ?? 'Error').toString(),
                            ),
                            backgroundColor: result['success'] == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _loadData();
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Zuia/Washa
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final newStatus = member['status'] == 'ACTIVE'
                          ? 'INACTIVE'
                          : 'ACTIVE';
                      Navigator.pop(context);
                      final result = await AdminService.updateMemberStatus(
                        member['id'] as int,
                        newStatus,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['success'] == true
                                  ? newStatus == 'ACTIVE'
                                        ? 'member_activated_success'.tr(context)
                                      : 'member_deactivated_success'
                                          .tr(context)
                                  : (result['message'] ?? 'Error').toString(),
                            ),
                            backgroundColor: result['success'] == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _loadData();
                      }
                    },
                    icon: Icon(
                      member['status'] == 'ACTIVE'
                          ? Icons.block
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      member['status'] == 'ACTIVE'
                          ? 'deactivate_member'.tr(context)
                          : 'activate_member'.tr(context),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: member['status'] == 'ACTIVE'
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Futa Mwanachama (ADMIN pekee)
              if (_role == 'ADMIN')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('delete_member_title'.tr(context)),
                          content: Text(
                            '${'delete_member_confirmation'.tr(context)} ${member['first_name']}? ${'delete_member_irreversible'.tr(context)}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('no_button'.tr(context)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                              child: Text('yes_delete_button'.tr(context)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        Navigator.pop(context); // Funga sheet
                        final result = await AdminService.deleteMember(
                          member['id'] as int,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                (result['message'] ??
                                        'deleted_successfully'.tr(context))
                                    .toString(),
                              ),
                              backgroundColor: result['success'] == true
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                          );
                          _loadData();
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.delete_forever,
                      color: AppTheme.errorColor,
                    ),
                    label: Text(
                      'delete_member_permanently'.tr(context),
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
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
        title: Text(
          '${'admin_members_title'.tr(context)} (${_members.length})',
        ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'search_member_hint'.tr(context),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _search('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
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

                // Members List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 80,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'no_members_found'.tr(context),
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
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) =>
                                _buildMemberCard(_filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isActive = member['status'] == 'ACTIVE';

    return GestureDetector(
      onTap: () => _showMemberDetails(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isActive ? AppTheme.primaryColor : Colors.grey,
              child: Text(
                '${member['first_name'][0]}${member['last_name'][0]}',
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
                    '${member['first_name']} ${member['last_name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member['phone_number'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member['group_name'] ?? '-',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _roleBadge(member['role'] ?? 'role_member'.tr(context)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive
                        ? 'status_active'.tr(context)
                        : 'status_inactive'.tr(context),
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'role_${role.toLowerCase()}'.tr(context),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    return 'role_${role.toLowerCase()}'.tr(context);
  }
}
