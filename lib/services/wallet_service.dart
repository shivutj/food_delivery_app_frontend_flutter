// lib/services/wallet_service.dart - WALLET API SERVICE
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class WalletService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  // GET WALLET BALANCE
  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/wallets'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Get wallet error: $e');
      return null;
    }
  }

  // GET TRANSACTION HISTORY
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/wallets/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
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
}
