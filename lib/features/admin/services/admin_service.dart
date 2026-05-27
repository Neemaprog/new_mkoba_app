import '../../../core/database/database_helper.dart';
import '../../notifications/notifications_service.dart';

class AdminService {
  // ========== MEMBERS ==========
  static Future<List<Map<String, dynamic>>> getAllMembers() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery('''
        SELECT u.*, g.name as group_name 
        FROM users u
        LEFT JOIN groups g ON u.group_id = g.id
        ORDER BY u.created_at DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateMemberStatus(
    int userId,
    String status,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  static Future<Map<String, dynamic>> deleteMember(int userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {'status': 'DELETED', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return {'success': true, 'message': 'Mwanachama amefutwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo wakati wa kufuta'};
    }
  }

  static Future<Map<String, dynamic>> updateMemberRole(
    int userId,
    String role,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      // 1. Tuma taarifa KABLA ya uteuzi 
      String roleLabel = _getRoleLabel(role);
      String message = role == 'MEMBER'
          ? 'Umeondolewa kwenye nafasi ya uongozi na kurudishwa kuwa mwanachama wa kawaida.'
          : 'Hongera! Umeteuliwa kuwa $roleLabel wa kikundi. Sasa unaweza kuaccess dashibodi ya uongozi.';

      await NotificationsService.addNotification(
        title: 'Mabadiliko ya Jukumu',
        message: message,
        type: 'SYSTEM',
        priority: 'HIGH',
        recipientType: 'USER',
        userId: userId,
      );

      // 2. Fanya uteuzi/mabadiliko kwenye database
      await db.update(
        'users',
        {'role': role, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  static String _getRoleLabel(String role) {
    switch (role) {
      case 'CHAIRPERSON': return 'Mwenyekiti';
      case 'TREASURER': return 'Mweka Hazina';
      case 'ACCOUNTANT': return 'Mhasibu';
      case 'SECRETARY': return 'Katibu';
      default: return 'Mwanachama';
    }
  }

  // ========== LOANS ==========
  static Future<List<Map<String, dynamic>>> getAllLoans() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery('''
        SELECT l.*, u.first_name, u.last_name, u.phone_number
        FROM loans l
        LEFT JOIN users u ON l.user_id = u.id
        ORDER BY l.created_at DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLoansByStatus(
    String status,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery(
        '''
        SELECT l.*, u.first_name, u.last_name, u.phone_number
        FROM loans l
        LEFT JOIN users u ON l.user_id = u.id
        WHERE l.status = ?
        ORDER BY l.created_at DESC
      ''',
        [status],
      );
    } catch (e) {
      return [];
    }
  }

  // CHAIRPERSON - Approve loan
  static Future<Map<String, dynamic>> approveLoan(
    int loanId,
    String reason,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      // Pata loan info
      final loans = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loanId],
      );
      if (loans.isEmpty) {
        return {'success': false, 'message': 'Mkopo haukupatikana'};
      }
      final loan = loans.first;

      await db.update(
        'loans',
        {
          'status': 'PENDING_TREASURER_CONFIRMATION',
          'approval_date': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );

      // Tuma notification kwa mwanachama
      await NotificationsService.addNotification(
        title: 'Mkopo Umeidhinishwa',
        message:
            'Mkopo wako wa TZS ${loan['amount']} umeidhinishwa na Mwenyekiti. Unasubiri uthibitisho wa Mweka Hazina.',
        type: 'LOAN',
        priority: 'HIGH',
        recipientType: 'USER',
        userId: loan['user_id'] as int,
      );

      return {'success': true, 'message': 'Mkopo umeidhinishwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  // TREASURER - Confirm loan
  static Future<Map<String, dynamic>> confirmLoan(
    int loanId,
    String reason,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      final loans = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loanId],
      );
      if (loans.isEmpty) {
        return {'success': false, 'message': 'Mkopo haukupatikana'};
      }
      final loan = loans.first;

      await db.update(
        'loans',
        {
          'status': 'ACTIVE',
          'treasurer_confirmation_date': now,
          'treasurer_confirmation_reason': reason,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );

      // Ongeza transaction ya disbursement
      await db.insert('transactions', {
        'user_id': loan['user_id'],
        'group_id': loan['group_id'],
        'amount': loan['amount'],
        'type': 'LOAN_DISBURSEMENT',
        'transaction_date': now,
        'description': 'Mkopo umetolewa',
        'reference_number': 'DIS${loanId.toString().padLeft(6, '0')}',
        'status': 'COMPLETED',
        'created_at': now,
        'updated_at': now,
      });

      // Tuma notification
      await NotificationsService.addNotification(
        title: 'Mkopo Umethibitishwa!',
        message:
            'Hongera! Mkopo wako wa TZS ${loan['amount']} umethibitishwa. Pesa zitawasilishwa hivi karibuni.',
        type: 'LOAN',
        priority: 'HIGH',
        recipientType: 'USER',
        userId: loan['user_id'] as int,
      );

      return {'success': true, 'message': 'Mkopo umethibitishwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  // Reject loan
  static Future<Map<String, dynamic>> rejectLoan(
    int loanId,
    String reason,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      final loans = await db.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loanId],
      );
      if (loans.isEmpty) {
        return {'success': false, 'message': 'Mkopo haukupatikana'};
      }
      final loan = loans.first;

      await db.update(
        'loans',
        {
          'status': 'REJECTED',
          'treasurer_confirmation_reason': reason,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loanId],
      );

      // Tuma notification
      await NotificationsService.addNotification(
        title: 'Mkopo Umekataliwa',
        message: 'Mkopo wako umekataliwa. Sababu: $reason',
        type: 'LOAN',
        priority: 'HIGH',
        recipientType: 'USER',
        userId: loan['user_id'] as int,
      );

      return {'success': true, 'message': 'Mkopo umekataliwa'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  // ========== SAVINGS ==========
  static Future<List<Map<String, dynamic>>> getAllSavings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.rawQuery('''
        SELECT s.*, u.first_name, u.last_name, g.name as group_name
        FROM savings s
        LEFT JOIN users u ON s.user_id = u.id
        LEFT JOIN groups g ON u.group_id = g.id
        ORDER BY s.contribution_date DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  // ========== GROUPS ==========
  static Future<List<Map<String, dynamic>>> getAllGroups() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query('groups', orderBy: 'created_at DESC');
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
    required String meetingFrequency,
    required double monthlyContribution,
    required double maxLoanAmount,
    required double interestRate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      await db.insert('groups', {
        'name': name,
        'description': description,
        'meeting_frequency': meetingFrequency,
        'monthly_contribution': monthlyContribution,
        'max_loan_amount': maxLoanAmount,
        'interest_rate': interestRate,
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });
      return {'success': true, 'message': 'Kikundi kimeundwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Jina hilo lipo tayari'};
    }
  }

  static Future<Map<String, dynamic>> updateGroup({
    required int groupId,
    required String name,
    required String description,
    required String meetingFrequency,
    required double monthlyContribution,
    required double maxLoanAmount,
    required double interestRate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'groups',
        {
          'name': name,
          'description': description,
          'meeting_frequency': meetingFrequency,
          'monthly_contribution': monthlyContribution,
          'max_loan_amount': maxLoanAmount,
          'interest_rate': interestRate,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [groupId],
      );
      return {'success': true, 'message': 'Kikundi kimesasishwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo'};
    }
  }

  static Future<Map<String, dynamic>> deleteGroup(int groupId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        // Zima kikundi
        await txn.update(
          'groups',
          {'active': 0, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [groupId],
        );
        // Ondoa wanachama kwenye kikundi hiki
        await txn.update(
          'users',
          {'group_id': null, 'updated_at': now},
          where: 'group_id = ?',
          whereArgs: [groupId],
        );
      });
      return {'success': true, 'message': 'Kikundi kimefutwa!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo wakati wa kufuta'};
    }
  }

  // ========== DASHBOARD STATS ==========
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final members = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE status = "ACTIVE" AND role != "ADMIN"',
      );
      final totalSavings = await db.rawQuery(
        'SELECT SUM(amount) as total FROM savings',
      );
      final activeLoans = await db.rawQuery(
        'SELECT COUNT(*) as count FROM loans WHERE status = "ACTIVE"',
      );
      final pendingLoans = await db.rawQuery(
        'SELECT COUNT(*) as count FROM loans WHERE status = "PENDING"',
      );
      final pendingConfirmation = await db.rawQuery(
        'SELECT COUNT(*) as count FROM loans WHERE status = "PENDING_TREASURER_CONFIRMATION"',
      );
      final totalLoans = await db.rawQuery(
        'SELECT SUM(total_amount) as total FROM loans WHERE status != "REJECTED"',
      );

      return {
        'totalMembers': (members.first['count'] as int?) ?? 0,
        'totalSavings': (totalSavings.first['total'] as num?)?.toDouble() ?? 0.0,
        'activeLoans': (activeLoans.first['count'] as int?) ?? 0,
        'pendingLoans': (pendingLoans.first['count'] as int?) ?? 0,
        'pendingConfirmation':
            (pendingConfirmation.first['count'] as int?) ?? 0,
        'totalLoans': (totalLoans.first['total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return {
        'totalMembers': 0,
        'totalSavings': 0.0,
        'activeLoans': 0,
        'pendingLoans': 0,
        'pendingConfirmation': 0,
        'totalLoans': 0.0,
      };
    }
  }
}
