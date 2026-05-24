import '../../core/database/database_helper.dart';

class LoansService {
  // Pata loans zote za mtumiaji
  static Future<List<Map<String, dynamic>>> getUserLoans(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final loans = await db.query(
        'loans',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'application_date DESC',
      );
      return loans;
    } catch (e) {
      return [];
    }
  }

  // Omba mkopo mpya
  static Future<Map<String, dynamic>> applyLoan({
    required int userId,
    required int groupId,
    required double amount,
    required String purpose,
    String? guarantor,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Pata interest rate ya group
      final groups = await db.query(
        'groups',
        where: 'id = ?',
        whereArgs: [groupId],
      );
      final interestRate = groups.isNotEmpty
          ? (groups.first['interest_rate'] as double)
          : 10.0;

      final totalAmount = amount + (amount * interestRate / 100);
      final now = DateTime.now().toIso8601String();

      await db.insert('loans', {
        'user_id': userId,
        'group_id': groupId,
        'amount': amount,
        'interest_rate': interestRate,
        'total_amount': totalAmount,
        'amount_paid': 0.0,
        'remaining_balance': totalAmount,
        'application_date': now,
        'status': 'PENDING',
        'purpose': purpose,
        'guarantor': guarantor ?? '',
        'created_at': now,
        'updated_at': now,
      });

      return {'success': true, 'message': 'Maombi yametumwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }

  // Lipa mkopo
  static Future<Map<String, dynamic>> repayLoan({
    required int loanId,
    required int userId,
    required int groupId,
    required double amount,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Pata loan
      final loans = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loanId],
      );

      if (loans.isEmpty) {
        return {'success': false, 'message': 'Mkopo haukupatikana'};
      }

      final loan = loans.first;
      final amountPaid = (loan['amount_paid'] as num).toDouble() + amount;
      final remaining = (loan['remaining_balance'] as num).toDouble() - amount;
      final status = remaining <= 0 ? 'COMPLETED' : 'ACTIVE';
      final now = DateTime.now().toIso8601String();

      await db.update(
        'loans',
        {
          'amount_paid': amountPaid,
          'remaining_balance': remaining <= 0 ? 0.0 : remaining,
          'status': status,
          'completion_date': remaining <= 0 ? now : null,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );

      // Ongeza transaction
      await db.insert('transactions', {
        'user_id': userId,
        'group_id': groupId,
        'amount': amount,
        'type': 'LOAN_REPAYMENT',
        'transaction_date': now,
        'description': 'Malipo ya mkopo #$loanId',
        'reference_number': 'REP${loanId.toString().padLeft(6, '0')}',
        'status': 'COMPLETED',
        'created_at': now,
        'updated_at': now,
      });

      return {'success': true, 'message': 'Malipo yamefanikiwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }
}
