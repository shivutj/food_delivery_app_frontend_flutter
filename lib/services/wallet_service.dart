// lib/services/wallet_service.dart - User wallet service
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';

class WalletService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/wallets'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {'balance': 0, 'total_earned': 0, 'total_spent': 0};
    } catch (e) {
      print('Get wallet error: $e');
      return {'balance': 0, 'total_earned': 0, 'total_spent': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/wallets/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      }

      return [];
    } catch (e) {
      print('Get transactions error: $e');
      return [];
    }
  }

  Future<bool> addCoins(int amount, String description,
      {String? referenceId}) async {
    try {
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/wallets/add-coins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'description': description,
          'reference_id': referenceId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Add coins error: $e');
      return false;
    }
  }
}
