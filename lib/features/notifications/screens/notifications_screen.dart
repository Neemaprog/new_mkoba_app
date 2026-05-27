import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/auth_service.dart';
import '../notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await AuthService.getUserInfo();
    _userId = int.tryParse(userInfo['id'] ?? '0') ?? 0;
    final notifications = await NotificationsService.getUserNotifications(
      _userId,
    );
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationsService.markAllAsRead(_userId);
    _loadData();
  }

  Future<void> _markRead(int id) async {
    await NotificationsService.markAsRead(id);
    _loadData();
  }

  Future<void> _delete(int id) async {
    await NotificationsService.deleteNotification(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] == 0).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Arifa'),
            if (unread > 0) ...{
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            },
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Soma Zote',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) =>
                    _buildCard(_notifications[index]),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == 1;
    final type = notification['type'] ?? 'ANNOUNCEMENT';
    final priority = notification['priority'] ?? 'MEDIUM';

    final Color priorityColor = priority == 'HIGH'
        ? AppTheme.errorColor
        : priority == 'LOW'
        ? AppTheme.textSecondary
        : AppTheme.primaryColor;

    final IconData typeIcon = _getTypeIcon(type);

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(notification['id'] as int),
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markRead(notification['id'] as int);
          }
          _showDetail(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: priorityColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] ?? '',
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
                        // Type badge
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
                        // Date
                        Text(
                          _formatDate(notification['created_at']),
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
      ),
    );
  }

  void _showDetail(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(notification['type'] ?? ''),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              notification['message'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aina: ${_getTypeLabel(notification['type'] ?? '')}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDate(notification['created_at']),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FUNGA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Hakuna arifa',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arifa zako zitaonekana hapa',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return '';
    }
  }
}
