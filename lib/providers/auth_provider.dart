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
  String? get token => _token;
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

  Future<String?> login(String email, String password) async {
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
          return null; // Success
        }
      }
      _isLoading = false;
      notifyListeners();
      return 'Đăng nhập thất bại';
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.response?.statusCode == 403) {
        return 'unverified';
      }
      return e.response?.data['message'] ?? 'Email hoặc mật khẩu không chính xác';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Đã có lỗi xảy ra';
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmedPassword,
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
          'confirmed_password': confirmedPassword,
          'username': username,
          'full_name': fullName,
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

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/auth/resend-otp',
        data: {
          'email': email,
        },
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? gender,
    String? birthDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Gọi đúng endpoint Backend: PUT /api/v1/user/profile
      final response = await _dio.put(
        '/user/profile',
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          if (gender != null) 'gender': gender,
          if (birthDate != null) 'date_of_birth': birthDate,
        },
      );

      if (response.statusCode == 200) {
        // Cập nhật State cục bộ ngay lập tức
        if (_user != null) {
          _user = User(
            id: _user!.id,
            username: _user!.username,
            email: _user!.email,
            roleId: _user!.roleId,
            isPremium: _user!.isPremium,
            fullName: fullName,
            phoneNumber: phoneNumber,
            gender: gender ?? _user!.gender,
            birthDate: birthDate ?? _user!.birthDate,
          );
        }

        await _fetchProfile(); // Đồng bộ lại từ server
        _isLoading = false;
        notifyListeners();
        return null; // Trả về null nghĩa là thành công
      }
      _isLoading = false;
      notifyListeners();
      return 'Cập nhật không thành công (${response.statusCode})';
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.response?.data['message'] ?? 'Lỗi kết nối đến server';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Đã có lỗi xảy ra: $e';
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

      dynamic userData = (data['data'] != null) ? data['data'] : data;
      if (userData is List && userData.isNotEmpty) {
        userData = userData[0];
      }
      
      // FIX 1: Khớp với Backend trả về key là "profile" thay vì "user_profiles"
      if (userData != null && userData['profile'] != null) {
        final profileData = userData['profile'];
        // Xử lý cả trường hợp profile là Object hoặc List 1 phần tử
        final profile = (profileData is List && profileData.isNotEmpty) ? profileData[0] : profileData;
        if (profile is Map) {
          // Gộp dữ liệu từ profile vào userData để lấy full_name, phone_number...
          userData = {...userData, ...Map<String, dynamic>.from(profile)};
        }
      }

      if (userData == null) return;

      // FIX: Bóc tách stats từ object lồng nhau trả về từ Backend
      if (userData['stats'] != null) {
        final statsMap = Map<String, dynamic>.from(userData['stats']);
        _userStats = UserStats.fromJson(statsMap);
      } else {
        // Fallback nếu không có stats
        _userStats = UserStats(
          currentStreak: 0,
          maxStreak: 0,
          totalExp: 0,
          level: 1,
          lastStudyDate: null,
        );
      }

      // Map API response to User model
      final dynamic idValue = userData['user_id'] ?? userData['id'] ?? userData['sub'];
      
      _user = User(
        id: (idValue ?? '0').toString(),
        username: userData['username'] ?? userData['email']?.split('@')[0] ?? 'user',
        email: userData['email'] ?? '',
        fullName: userData['full_name'] ?? userData['name'] ?? '',
        // FIX 3: Khớp với Backend trả về "role_id"
        roleId: (userData['role_id'] ?? userData['role'] ?? 'user').toString(),
        isPremium: userData['is_premium'] == true,
        phoneNumber: userData['phone_number'],
        gender: userData['gender'],
        birthDate: userData['birth_date'] ?? userData['date_of_birth'],
      );

      await _fetchStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    await _fetchProfile();
    await _fetchStats();
  }

  // Method to spend XP
  Future<bool> spendXP(int amount) async {
    if (_userStats == null || _user == null || _userStats!.totalExp < amount) {
      return false;
    }

    final int newTotalExp = _userStats!.totalExp - amount;
    final int newLevel = newTotalExp ~/ 100 + 1;

    _userStats = _userStats!.copyWith(
      totalExp: newTotalExp,
      level: newLevel,
    );
    notifyListeners();

    try {
      await _dio.put('/stats/${_user!.id}', data: {
        'current_streak': _userStats!.currentStreak,
        'max_streak': _userStats!.maxStreak,
        'total_exp': newTotalExp,
        'level': newLevel,
        'last_study_date': _userStats!.lastStudyDate,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchStats() async {
    if (_user == null) return;
    try {
      final response = await _dio.get('/stats/${_user!.id}');
      if (response.statusCode == 200) {
        final data = (response.data['data'] != null) ? response.data['data'] : response.data;
        
        // Tính toán level dựa trên total_exp (100 exp = 1 level)
        final int exp = data['total_exp'] ?? 0;
        final int calculatedLevel = (exp ~/ 100) + 1;
        
        _userStats = UserStats.fromJson(data).copyWith(level: calculatedLevel);
        notifyListeners();
      }
    } catch (e) {
      // Logic for new users who don't have stats yet
      _userStats = UserStats(
        currentStreak: 0,
        maxStreak: 0,
        totalExp: 0,
        level: 1,
        lastStudyDate: null,
      );
      notifyListeners();
    }
  }

  // Method to increment EXP and update Streak
  void addStudyProgress(int expEarned) async {
    if (_userStats == null || _user == null) return;
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int newStreak = _userStats!.currentStreak;
    int newMaxStreak = _userStats!.maxStreak;

    if (_userStats!.lastStudyDate != today) {
      newStreak++;
      if (newStreak > newMaxStreak) {
        newMaxStreak = newStreak;
      }
    }

    final int newTotalExp = _userStats!.totalExp + expEarned;
    final int newLevel = newTotalExp ~/ 100 + 1;

    _userStats = _userStats!.copyWith(
      currentStreak: newStreak,
      maxStreak: newMaxStreak,
      totalExp: newTotalExp,
      level: newLevel,
      lastStudyDate: today,
    );

    notifyListeners();

    // Sync to BE
    try {
      await _dio.put('/stats/${_user!.id}', data: {
        'current_streak': newStreak,
        'max_streak': newMaxStreak,
        'total_exp': newTotalExp,
        'level': newLevel,
        'last_study_date': today,
      });
    } catch (e) {
      print('Sync stats failed: $e');
    }
  }
}
