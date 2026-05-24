import '../../core/database/database_helper.dart';

class GroupsService {
  // Pata group ya mtumiaji
  static Future<Map<String, dynamic>?> getUserGroup(int groupId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final groups = await db.query(
        'groups',
        where: 'id = ?',
        whereArgs: [groupId],
      );
      return groups.isNotEmpty ? groups.first : null;
    } catch (e) {
      return null;
    }
  }

  // Pata wanachama wa group
  static Future<List<Map<String, dynamic>>> getGroupMembers(int groupId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query(
        'users',
        where: 'group_id = ? AND status = ?',
        whereArgs: [groupId, 'ACTIVE'],
      );
    } catch (e) {
      return [];
    }
  }

  // Pata summary ya group
  static Future<Map<String, dynamic>> getGroupSummary(int groupId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final savingsResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM savings WHERE group_id = ?',
        [groupId],
      );
      final loansResult = await db.rawQuery(
        'SELECT SUM(remaining_balance) as total FROM loans WHERE group_id = ? AND status = "ACTIVE"',
        [groupId],
      );
      final membersResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM users WHERE group_id = ? AND status = "ACTIVE"',
        [groupId],
      );

      return {
        'totalSavings':
            (savingsResult.first['total'] as num?)?.toDouble() ?? 0.0,
        'totalLoans': (loansResult.first['total'] as num?)?.toDouble() ?? 0.0,
        'memberCount': (membersResult.first['total'] as int?) ?? 0,
      };
    } catch (e) {
      return {'totalSavings': 0.0, 'totalLoans': 0.0, 'memberCount': 0};
    }
  }
}
