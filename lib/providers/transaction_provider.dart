import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/membership_plan.dart';
import '../utils/constants.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<MembershipPlan> _plans = [];
  bool _isLoading = false;
  String? _error;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  void updateToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  List<TransactionModel> get transactions => _transactions;
  List<MembershipPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách gói Membership từ BE
  Future<void> fetchMembershipPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _dio.get('/memberships');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _plans = data.map((json) => MembershipPlan.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "Không thể tải danh sách gói hội viên.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy lịch sử giao dịch (Receipts) từ BE theo userId
  Future<void> fetchTransactions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/receipts/user/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _transactions = data.map((json) {
          final mId = json['membershipId'];
          final plan = _plans.cast<MembershipPlan?>().firstWhere((p) => p?.id == mId, orElse: () => null);

          return TransactionModel(
            id: json['id']?.toString() ?? '',
            userId: json['user_id']?.toString() ?? '',
            amount: (json['total'] as num?)?.toDouble() ?? 0.0,
            planName: plan?.name ?? 'Gói Premium #$mId',
            status: json['is_paid'] == true ? 'success' : 'pending',
            createdAt: json['dayCreated'] != null 
                ? DateTime.parse(json['dayCreated']) 
                : DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      _error = "Không thể tải lịch sử giao dịch.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kiểm tra trạng thái một biên lai cụ thể
  Future<bool> checkReceiptStatus(String receiptId, String userId) async {
    try {
      // Gọi đúng endpoint lấy receipts của user
      await fetchTransactions(userId);
      
      // Tìm receipt trong danh sách đã load
      final tx = _transactions.cast<TransactionModel?>().firstWhere(
        (element) => element?.id == receiptId,
        orElse: () => null,
      );
      
      return tx?.status == 'success';
    } catch (e) {
      return false;
    }
  }

  // Tạo giao dịch thanh toán (Ví dụ qua VNPay)
  Future<Map<String, dynamic>?> createPaymentRequest({
    required String userId,
    required int membershipId,
    required double amount,
  }) async {
    if (userId == '0' || userId.isEmpty) {
      _error = "Lỗi: Không tìm thấy thông tin người dùng.";
      notifyListeners();
      return null;
    }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Đảm bảo dữ liệu gửi đi sạch sẽ nhất
      final response = await _dio.post('/vnpay/create', data: {
        'user_id': int.parse(userId),
        'membershipId': membershipId,
        'paymentMethod': 'vnpay',
      });

      if (response.statusCode == 200) {
        final resData = response.data['data'];
        
        // BE trả về Object: { paymentUrl, receiptId, total }
        final String url = resData['paymentUrl'].toString();
        final String receiptId = resData['receiptId'].toString();
        
        return {
          'url': url,
          'receiptId': receiptId,
        };
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? "Lỗi tạo link thanh toán (400).";
    } catch (e) {
      _error = "Lỗi hệ thống: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
