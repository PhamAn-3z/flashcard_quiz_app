import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Sử dụng Mock Data vì không được chỉnh sửa Backend
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Giả lập độ trễ mạng
      await Future.delayed(const Duration(seconds: 1));

      // Dữ liệu mẫu (Mock Data) phù hợp với yêu cầu FE
      _transactions = [
        TransactionModel(
          id: 'TX123456',
          userId: 'user_01',
          amount: 699000,
          planName: 'Gói Premium Hàng Năm',
          status: 'success',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TransactionModel(
          id: 'TX123457',
          userId: 'user_01',
          amount: 99000,
          planName: 'Gói Premium Hàng Tháng',
          status: 'success',
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
        ),
      ];
    } catch (e) {
      _error = "Không thể tải lịch sử giao dịch.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
