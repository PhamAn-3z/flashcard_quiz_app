import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/deck.dart';
import '../models/transaction.dart';

class AdminProvider with ChangeNotifier {
  String? _token;
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // --- User Management ---
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Backend might need a specific endpoint for list users, 
      // based on provided info, let's assume /admin/users or similar.
      // If not specifically provided, we'll try to get all users.
      final response = await _dio.get('/admin/users'); 
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint("Error fetching users: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> warnUser(String userId, String reason) async {
    try {
      await _dio.post('/admin/users/$userId/warning', data: {'reason': reason});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> tempBanUser(String userId, String reason, int days) async {
    try {
      await _dio.post('/admin/users/$userId/temp-ban', data: {'reason': reason, 'days': days});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> permBanUser(String userId, String reason) async {
    try {
      await _dio.post('/admin/users/$userId/permanent-ban', data: {'reason': reason});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> fetchUserPenalties(String userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId/penalties');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // --- Financial Management ---
  Future<List<Map<String, dynamic>>> fetchAllReceipts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('/receipts/');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cleanupReceipts() async {
    try {
      await _dio.delete('/receipts/cleanup');
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Content Management ---
  Future<List<Deck>> fetchAllDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      // API GET /api/v1/decks/ as Admin returns ALL decks
      final response = await _dio.get('/decks/');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
