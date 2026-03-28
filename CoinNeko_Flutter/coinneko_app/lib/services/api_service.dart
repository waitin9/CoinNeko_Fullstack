// frontend/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  final AuthService _authService;

  ApiService(this._authService);

  // ── 帶 JWT 的 headers ──
  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getValidAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractError(body),
      );
    }
    return body as Map<String, dynamic>;
  }

  String _extractError(dynamic body) {
    if (body is Map && body.containsKey('error')) return body['error'].toString();
    if (body is Map && body.containsKey('detail')) return body['detail'].toString();
    return '未知錯誤';
  }

  // ──────────────────────────────────────────────
  // Categories
  // ──────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'));
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ──────────────────────────────────────────────
  // Transactions
  // ──────────────────────────────────────────────
  Future<List<Transaction>> getTransactions({String? month}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/transactions/').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: headers);
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createTransaction({
    required int categoryId,
    required double amount,
    String note = '',
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/create/'),
      headers: headers,
      body: jsonEncode({
        'category': categoryId,
        'amount': amount,
        'note': note,
      }),
    );
    return _handleResponse(response);
  }

  Future<void> deleteTransaction(int id) async {
    final headers = await _authHeaders();
    await http.delete(Uri.parse('$baseUrl/transactions/$id/'), headers: headers);
  }

  // ──────────────────────────────────────────────
  // Summary
  // ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getSummary({String? month}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/summary/').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  // ──────────────────────────────────────────────
  // Budgets
  // ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBudgets({String? month}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/budgets/').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: headers);
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> createBudget({
    required int categoryId,
    required String month,
    required double limitAmount,
  }) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/budgets/create/'),
      headers: headers,
      body: jsonEncode({
        'category_id': categoryId,
        'month': month,
        'limit_amount': limitAmount,
      }),
    );
  }

  // ──────────────────────────────────────────────
  // Cat Collection
  // ──────────────────────────────────────────────
  Future<List<CatSpecies>> getCatSpecies() async {
    final response = await http.get(Uri.parse('$baseUrl/cats/species/'));
    if (response.statusCode >= 400) {
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractError(
          jsonDecode(utf8.decode(response.bodyBytes))),
    );
  }
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => CatSpecies.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserCat>> getCollection() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/cats/collection/'),
      headers: headers,
    );
    if (response.statusCode >= 400) {
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractError(
          jsonDecode(utf8.decode(response.bodyBytes))),
    );
  }
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => UserCat.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ──────────────────────────────────────────────
  // Gacha
  // ──────────────────────────────────────────────
  Future<GachaPullResult> gachaPull({bool useCoins = false}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/gacha/pull/'),
      headers: headers,
      body: jsonEncode({'use_coins': useCoins}),
    );
    final data = await _handleResponse(response);
    return GachaPullResult.fromJson(data);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}