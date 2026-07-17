import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/deck.dart';
import '../models/transaction.dart';

class AdminProvider with ChangeNotifier {
  String? _token;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    contentType: 'application/json',
  ));

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      final message = e.response?.data?['message'] ?? e.response?.data?['error'];
      if (message != null) return message.toString();
      return e.message ?? "Lỗi kết nối server";
    }
    return e.toString();
  }

  // --- User Management ---
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('admin/users'); 
      _users = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      return _users;
    } catch (e) {
      debugPrint("Error fetching users: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> warnUser(String userId, String reason) async {
    try {
      await _dio.post('admin/users/$userId/warning', data: {'reason': reason});
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> tempBanUser(String userId, String reason, int days) async {
    try {
      await _dio.post('admin/users/$userId/temp-ban', data: {'reason': reason, 'days': days});
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> permBanUser(String userId, String reason) async {
    try {
      await _dio.post('admin/users/$userId/permanent-ban', data: {'reason': reason});
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> fetchUserPenalties(String userId) async {
    try {
      final response = await _dio.get('admin/users/$userId/penalties');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // --- Financial Management ---
  Future<List<Map<String, dynamic>>> fetchAllReceipts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('receipts');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> cleanupReceipts() async {
    try {
      await _dio.delete('receipts/cleanup');
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  // --- Content Management ---
  Future<List<Deck>> fetchAllDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('decks');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Membership Management ---
  List<Map<String, dynamic>> _memberships = [];
  List<Map<String, dynamic>> get memberships => _memberships;

  Future<List<Map<String, dynamic>>> fetchAllMemberships() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('memberships/');
      _memberships = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      return _memberships;
    } catch (e) {
      debugPrint("Error fetching memberships: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createMembership(Map<String, dynamic> data) async {
    try {
      await _dio.post('memberships/', data: data);
      return null;
    } catch (e) {
      debugPrint("Error creating membership: $e");
      return _handleError(e);
    }
  }

  Future<String?> updateMembership(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('memberships/$id', data: data);
      return null;
    } catch (e) {
      debugPrint("Error updating membership: $e");
      return _handleError(e);
    }
  }

  Future<String?> toggleMembershipStatus(int id) async {
    try {
      await _dio.patch('memberships/$id/toggle');
      return null;
    } catch (e) {
      debugPrint("Error toggling membership status: $e");
      return _handleError(e);
    }
  }

  // --- Promo Code Management ---
  List<Map<String, dynamic>> _promoCodes = [];
  List<Map<String, dynamic>> get promoCodes => _promoCodes;

  Future<List<Map<String, dynamic>>> fetchAllPromoCodes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get('promo-codes/');
      _promoCodes = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      return _promoCodes;
    } catch (e) {
      debugPrint("Error fetching promo codes: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createPromoCode(Map<String, dynamic> data) async {
    try {
      await _dio.post('promo-codes/', data: data);
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> updatePromoCode(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('promo-codes/$id', data: data);
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> togglePromoCodeStatus(int id) async {
    try {
      await _dio.patch('promo-codes/$id/toggle-expired');
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }
}
