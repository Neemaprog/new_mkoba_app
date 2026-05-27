import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/notifications_service.dart';
import '../services/admin_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true; // Keep this for loading state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Admin anapaswa kuona arifa zote zilizotumwa kwenye mfumo
    final notifications = await NotificationsService.getAllNotifications();
    final members = await AdminService.getAllMembers();
    setState(() {
      _notifications = notifications;
      _members = members.where((m) => m['role'] != 'ADMIN').toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteNotification(int id) async {
    await NotificationsService.deleteNotification(id);
    _loadData();
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'ANNOUNCEMENT';
    String selectedPriority = 'MEDIUM';
    String recipientType = 'ALL';
    int? selectedMemberId;

    final types = [
      'ANNOUNCEMENT',
      'REMINDER',
      'LOAN',
      'CONTRIBUTION',
      'SYSTEM',
    ];
    final priorities = ['HIGH', 'MEDIUM', 'LOW'];

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
                const Text(
                  'Tuma taarifa',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Kichwa cha Taarifa',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ujumbe',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Type
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Aina ya Taarifa',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: types
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_getTypeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),

                // Priority
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Kipaumbele',
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: priorities
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(_getPriorityLabel(p)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 12),

                // Recipient Type
                DropdownButtonFormField<String>(
                  initialValue: recipientType,
                  decoration: const InputDecoration(
                    labelText: 'Tuma Kwa',
                    prefixIcon: Icon(Icons.people_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text('Wanachama Wote'),
                    ),
                    DropdownMenuItem(
                      value: 'USER',
                      child: Text('Mwanachama Mmoja'),
                    ),
                  ],
                  onChanged: (val) => setModalState(() {
                    recipientType = val!;
                    selectedMemberId = null;
                  }),
                ),
                const SizedBox(height: 12),

                // Member selector
                if (recipientType == 'USER')
                  DropdownButtonFormField<int>(
                    initialValue: selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Chagua Mwanachama',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    items: _members
                        .map(
                          (m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text('${m['first_name']} ${m['last_name']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedMemberId = val),
                  ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tafadhali jaza kichwa na ujumbe'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    if (recipientType == 'USER' && selectedMemberId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tafadhali chagua mwanachama'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await NotificationsService.addNotification(
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                      type: selectedType,
                      priority: selectedPriority,
                      recipientType: recipientType,
                      userId: selectedMemberId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tarifa imetumwa!'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('TUMA TAARIFA'),
                ),
                const SizedBox(height: 8),
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
        title: const Text('Taarifa'),
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
        onPressed: _showSendNotificationDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.send, color: Colors.white),
        label: const Text(
          'Tuma taarifa',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Hakuna taarifa bado',
                    style: TextStyle(
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
                itemCount: _notifications.length,
                itemBuilder: (context, index) =>
                    _buildCard(_notifications[index]),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final type = n['type'] ?? 'ANNOUNCEMENT';
    final priority = n['priority'] ?? 'MEDIUM';
    final Color priorityColor = priority == 'HIGH'
        ? AppTheme.errorColor
        : priority == 'LOW'
        ? AppTheme.textSecondary
        : AppTheme.primaryColor;

    return Dismissible(
      key: Key(n['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Futa taarifa'),
            content: const Text(
              'Je, una uhakika unataka kufuta taarifa hii? Itaondolewa pia kwa wanachama wote waliotumiwa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('HAPANA'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('NDIO, FUTA'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteNotification(n['id'] as int),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getTypeIcon(type), color: priorityColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message'] ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getTypeLabel(type),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        n['created_at']?.toString().substring(0, 10) ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'LOAN':
        return Icons.account_balance_outlined;
      case 'CONTRIBUTION':
        return Icons.savings_outlined;
      case 'REMINDER':
        return Icons.alarm_outlined;
      case 'SYSTEM':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'LOAN':
        return 'Mkopo';
      case 'CONTRIBUTION':
        return 'Mchango';
      case 'REMINDER':
        return 'Kumbusho';
      case 'SYSTEM':
        return 'Mfumo';
      default:
        return 'Tangazo';
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'HIGH':
        return 'Juu';
      case 'LOW':
        return 'Chini';
      default:
        return 'Kati';
    }
  }
}
