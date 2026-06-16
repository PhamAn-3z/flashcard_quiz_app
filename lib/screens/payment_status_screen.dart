import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'main_navigation.dart';

class PaymentStatusScreen extends StatefulWidget {
  final bool isSuccess;
  final String? message;

  const PaymentStatusScreen({
    super.key,
    required this.isSuccess,
    this.message,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.isSuccess) {
      // Refresh profile to get VIP status immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().refreshProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: widget.isSuccess ? Colors.green : Colors.red,
                  size: 100,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isSuccess 
                  ? 'Chúc mừng! Gói Premium của bạn đã được kích hoạt. Hãy bắt đầu trải nghiệm ngay.'
                  : (widget.message ?? 'Giao dịch đã bị hủy hoặc có lỗi xảy ra trong quá trình xử lý. Vui lòng thử lại.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('QUAY LẠI TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (!widget.isSuccess) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Thử lại', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
