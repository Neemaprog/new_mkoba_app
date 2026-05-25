import '../../core/database/database_helper.dart';

class SavingsService {
  // Pata savings zote za mtumiaji
  static Future<List<Map<String, dynamic>>> getUserSavings(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final savings = await db.query(
        'savings',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'contribution_date DESC',
      );
      return savings;
    } catch (e) {
      return [];
    }
  }

  // Pata jumla ya savings
  static Future<double> getTotalSavings(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM savings WHERE user_id = ?',
        [userId],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Ongeza saving mpya
  static Future<Map<String, dynamic>> addSaving({
    required int userId,
    required int groupId,
    required double amount,
    required String type,
    String? description,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      final id = await db.insert('savings', {
        'user_id': userId,
        'group_id': groupId,
        'amount': amount,
        'contribution_date': now,
        'description': description ?? 'Mchango wa akiba',
        'type': type,
        'created_at': now,
        'updated_at': now,
      });

      // Ongeza transaction
      await db.insert('transactions', {
        'user_id': userId,
        'group_id': groupId,
        'amount': amount,
        'type': 'SAVINGS_CONTRIBUTION',
        'transaction_date': now,
        'description': description ?? 'Mchango wa akiba',
        'reference_number': 'SAV${id.toString().padLeft(6, '0')}',
        'status': 'COMPLETED',
        'created_at': now,
        'updated_at': now,
      });

      return {'success': true, 'message': 'Akiba imeongezwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }
}
