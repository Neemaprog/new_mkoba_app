import '../../core/database/database_helper.dart';

class TransactionsService {
  // Pata transactions zote za mtumiaji
  static Future<List<Map<String, dynamic>>> getUserTransactions(
    int userId,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final transactions = await db.query(
        'transactions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'transaction_date DESC',
      );
      return transactions;
    } catch (e) {
      return [];
    }
  }
}
