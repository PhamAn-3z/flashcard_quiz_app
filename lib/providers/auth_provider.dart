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
    // In a real app we'd likely verify the token with the backend 
    // and fetch the user profile here. 
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      // MOCK DATA for now since backend might not be fully ready
      await _fetchMockProfile();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // MOCK API CALL
      await Future.delayed(const Duration(seconds: 1));
      
      // Assume success for demonstration
      _token = "mock_token_123";
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      
      await _fetchMockProfile();
      _isLoading = false;
      notifyListeners();
      return true;
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
    String? gender,
    String? birthDate,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // MOCK API CALL
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _user = null;
    _userStats = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _dio.options.headers.remove('Authorization');
    notifyListeners();
  }

  Future<void> _fetchMockProfile() async {
    _user = User(
      id: '1',
      username: 'student_1',
      email: 'student@example.com',
      fullName: 'Nihongo Learner',
      role: 'user',
      isPremium: true,
    );
    _userStats = UserStats(
      currentStreak: 5,
      maxStreak: 12,
      totalExp: 1540,
      level: 4,
      lastStudyDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
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
