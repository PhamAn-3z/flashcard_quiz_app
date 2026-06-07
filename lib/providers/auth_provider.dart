import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_stats.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserStats? _userStats;
  String? _token;
  bool _isLoading = false;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  User? get user => _user;
  UserStats? get userStats => _userStats;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      try {
        await _fetchProfile();
      } catch (e) {
        _token = null;
        await prefs.remove('token');
        _dio.options.headers.remove('Authorization');
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'] ?? data['data']?['token'];
        
        if (_token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          _dio.options.headers['Authorization'] = 'Bearer $_token';
          
          await _fetchProfile();
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'username': username,
        },
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore error on logout call
    }
    
    _user = null;
    _userStats = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _dio.options.headers.remove('Authorization');
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      final data = response.data;
      
      final userData = (data['data'] != null) ? data['data'] : data;
      
      // Map API response to User model
      // If the API doesn't return an id or username we assign fallbacks
      _user = User(
        id: (userData['id'] ?? userData['sub'] ?? '0').toString(),
        username: userData['username'] ?? userData['email']?.split('@')[0] ?? 'user',
        email: userData['email'] ?? '',
        fullName: userData['full_name'] ?? userData['name'] ?? '',
        role: userData['role'] ?? 'user',
        isPremium: userData['is_premium'] == true,
      );

      // We still use mock stats for now unless API provides them
      _userStats = UserStats(
        currentStreak: userData['current_streak'] ?? 5,
        maxStreak: userData['max_streak'] ?? 12,
        totalExp: userData['total_exp'] ?? 1540,
        level: userData['level'] ?? 4,
        lastStudyDate: userData['last_study_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Method to increment EXP and update Streak
  void addStudyProgress(int expEarned) {
    if (_userStats == null) return;
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int newStreak = _userStats!.currentStreak;
    int newMaxStreak = _userStats!.maxStreak;

    if (_userStats!.lastStudyDate != today) {
      newStreak++;
      if (newStreak > newMaxStreak) {
        newMaxStreak = newStreak;
      }
    }

    _userStats = _userStats!.copyWith(
      currentStreak: newStreak,
      maxStreak: newMaxStreak,
      totalExp: _userStats!.totalExp + expEarned,
      level: (_userStats!.totalExp + expEarned) ~/ 500 + 1, // Basic level formula
      lastStudyDate: today,
    );

    notifyListeners();
  }
}
