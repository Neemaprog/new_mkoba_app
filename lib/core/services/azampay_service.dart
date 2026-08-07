import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/azampay_config.dart';

class AzamPayService {
  static String? _token;
  static DateTime? _tokenExpiry;

  // ========== PATA TOKEN ==========
  static Future<String?> _getToken() async {
    try {
      // Angalia kama token bado ni valid
      if (_token != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _token;
      }

      // Tengeneza Basic Auth Token
      final credentials =
          '${AzamPayConfig.clientId}:${AzamPayConfig.clientSecret}';
      final encodedCredentials = base64Encode(utf8.encode(credentials));

      final response = await http.post(
        Uri.parse(AzamPayConfig.authUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $encodedCredentials',
        },
        body: jsonEncode({'appName': AzamPayConfig.appName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _token = data['data']['accessToken'];
          // Token inaisha baada ya saa 1
          _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
          return _token;
        } else {
          // Angalia ujumbe wa kosa kutoka AzamPay
          print('AzamPay Token Error: ${data['message']}');
          return null;
        }
      } else {
        print('AzamPay Token HTTP Error: ${response.statusCode}');
        print('AzamPay Token Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('AzamPay Token Exception: $e');
      return null;
    }
  }

  // ========== LIPA KWA MNO (Airtel, Tigo, Mpesa, Halopesa) ==========
  static Future<Map<String, dynamic>> mnoPush({
    required String accountNumber,
    required String amount,
    required String externalId,
    required String provider,
    String currency = 'TZS',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Imeshindwa kupata token ya AzamPay',
        };
      }

      final response = await http.post(
        Uri.parse(AzamPayConfig.checkoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'accountNumber': accountNumber,
          'amount': amount,
          'currency': currency,
          'externalId': externalId,
          'provider': provider,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ombi limetumwa!',
          'transactionId': data['transactionId'] ?? '',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Imeshindwa kutuma ombi la malipo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Hakuna muunganisho wa intaneti'};
    }
  }

  // ========== CHANGIA AKIBA ==========
  static Future<Map<String, dynamic>> contributeToSavings({
    required String phoneNumber,
    required double amount,
    required String externalId,
  }) async {
    final provider = _detectProvider(phoneNumber);
    if (provider == null) {
      return {
        'success': false,
        'message':
            'Nambari ya simu haitambuliwi. Tumia Airtel, Tigo, Mpesa au Halopesa',
      };
    }

    return await mnoPush(
      accountNumber: phoneNumber,
      amount: amount.toStringAsFixed(0),
      externalId: externalId,
      provider: provider,
    );
  }

  // ========== LIPA MKOPO ==========
  static Future<Map<String, dynamic>> repayLoan({
    required String phoneNumber,
    required double amount,
    required String loanId,
  }) async {
    final provider = _detectProvider(phoneNumber);
    if (provider == null) {
      return {
        'success': false,
        'message':
            'Nambari ya simu haitambuliwi. Tumia Airtel, Tigo, Mpesa au Halopesa',
      };
    }

    return await mnoPush(
      accountNumber: phoneNumber,
      amount: amount.toStringAsFixed(0),
      externalId: 'LOAN_$loanId',
      provider: provider,
    );
  }

  // ========== TAMBUA MTOA HUDUMA ==========
  static String? _detectProvider(String phone) {
    // Ondoa spaces na dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Tanzania phone prefixes
    // Vodacom/Mpesa: 074, 075, 076
    // Tigo/Miitel: 071, 065, 067
    // Airtel: 068, 069, 078
    // Halotel: 062, 061

    if (cleaned.startsWith('074') ||
        cleaned.startsWith('075') ||
        cleaned.startsWith('076') ||
        cleaned.startsWith('+25574') ||
        cleaned.startsWith('+25575') ||
        cleaned.startsWith('+25576')) {
      return AzamPayConfig.mpesa;
    } else if (cleaned.startsWith('071') ||
        cleaned.startsWith('065') ||
        cleaned.startsWith('067') ||
        cleaned.startsWith('+25571') ||
        cleaned.startsWith('+25565') ||
        cleaned.startsWith('+25567')) {
      return AzamPayConfig.tigoPesa;
    } else if (cleaned.startsWith('068') ||
        cleaned.startsWith('069') ||
        cleaned.startsWith('078') ||
        cleaned.startsWith('+25568') ||
        cleaned.startsWith('+25569') ||
        cleaned.startsWith('+25578')) {
      return AzamPayConfig.airtelMoney;
    } else if (cleaned.startsWith('062') ||
        cleaned.startsWith('061') ||
        cleaned.startsWith('+25562') ||
        cleaned.startsWith('+25561')) {
      return AzamPayConfig.halopesa;
    }

    return null;
  }

  // ========== GENERATE EXTERNAL ID ==========
  static String generateExternalId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }
}
