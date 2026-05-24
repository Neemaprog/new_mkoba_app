import '../../../core/database/database_helper.dart';

class NotificationsService {
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    int userId,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final notifications = await db.rawQuery(
        '''
        SELECT * FROM notifications 
        WHERE user_id = ? 
        OR recipient_type = 'ALL'
        OR (recipient_type = 'GROUP' AND recipient_id = (
          SELECT group_id FROM users WHERE id = ?
        ))
        ORDER BY created_at DESC
      ''',
        [userId, userId],
      );
      return notifications;
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadCount(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM notifications 
        WHERE (user_id = ? OR recipient_type = 'ALL') 
        AND is_read = 0
      ''',
        [userId],
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> markAllAsRead(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.rawUpdate(
        '''
        UPDATE notifications SET is_read = 1 
        WHERE user_id = ? OR recipient_type = 'ALL'
      ''',
        [userId],
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    String type = 'ANNOUNCEMENT',
    String priority = 'MEDIUM',
    String recipientType = 'ALL',
    int? recipientId,
    int? userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('notifications', {
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': 0,
        'recipient_type': recipientType,
        'recipient_id': recipientId,
        'sent_via': 'APP',
        'delivery_status': 'DELIVERED',
        'user_id': userId,
      });
    } catch (e) {
      // ignore
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      // ignore
    }
  }
}
