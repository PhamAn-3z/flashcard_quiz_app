import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('Mã OTP phải có 6 chữ số', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    
    final success = await auth.verifyOtp(widget.email, otp);
    
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _showSnackBar('Xác thực thành công! Bạn có thể đăng nhập.', isError: false);
      // Trở về màn hình đăng nhập (xóa stack)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      if (!mounted) return;
      _showSnackBar('Mã OTP không đúng hoặc đã hết hạn', isError: true);
    }
  }

  void _resend() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    
    final success = await auth.resendOtp(widget.email);
    
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Đã gửi lại mã OTP tới email của bạn', isError: false);
    } else {
      _showSnackBar('Gửi lại mã thất bại. Vui lòng thử lại sau.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực Email'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Nhập mã OTP đã được gửi tới',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            Text(
              widget.email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resend,
              child: const Text('Gửi lại mã OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
