import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../core/database/database_helper.dart';

class AuthService {
  // Hash password
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final hashedPassword = _hashPassword(password);
      final users = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.trim().toLowerCase(), hashedPassword],
      );
      if (users.isEmpty) {
        return {'success': false, 'message': 'Email au nywila si sahihi'};
      }
      final user = users.first;
      if (user['status'] != 'ACTIVE') {
        return {'success': false, 'message': 'Akaunti yako imezuiwa'};
      }
      await _saveUserSession(user);
      return {'success': true, 'data': user};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String role = 'MEMBER',
    int groupId = 1,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
      );
      if (existing.isNotEmpty) {
        return {'success': false, 'message': 'Email hii ipo tayari'};
      }
      final now = DateTime.now().toIso8601String();
      await db.insert('users', {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'phone_number': phone.trim(),
        'password': _hashPassword(password),
        'group_id': groupId,
        'role': role,
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      });
      return {'success': true, 'message': 'Umesajiliwa kikamilifu!'};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Angalia kama mtumiaji ameingia
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') != null;
  }

  // Hifadhi session
  static Future<void> _saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user['id'] as int);
    await prefs.setString('user_first_name', user['first_name'] ?? '');
    await prefs.setString('user_last_name', user['last_name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_phone', user['phone_number'] ?? '');
    await prefs.setString('user_role', user['role'] ?? 'MEMBER');
    await prefs.setInt('group_id', user['group_id'] as int? ?? 1);
  }

  // Pata user info
  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('user_id')?.toString() ?? '0',
      'name':
          '${prefs.getString('user_first_name') ?? ''} ${prefs.getString('user_last_name') ?? ''}'
              .trim(),
      'email': prefs.getString('user_email') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
      'role': prefs.getString('user_role') ?? 'MEMBER',
      'group_id': prefs.getInt('group_id')?.toString() ?? '1',
    };
  }

  // Update profile
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'users',
        {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone_number': phone.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_first_name', firstName.trim());
      await prefs.setString('user_last_name', lastName.trim());
      await prefs.setString('user_phone', phone.trim());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final users = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [userId, _hashPassword(oldPassword)],
      );
      if (users.isEmpty) {
        return {'success': false, 'message': 'Nywila ya sasa si sahihi'};
      }
      await db.update(
        'users',
        {
          'password': _hashPassword(newPassword),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Kuna tatizo, jaribu tena'};
    }
  }
}
