import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Kiểm tra mật khẩu khớp nhau
      if (_password != _confirmPassword) {
        _showStyledSnackBar('Mật khẩu xác nhận không khớp!', isError: true);
        return;
      }
      
      setState(() => _isLoading = true);
      final auth = context.read<AuthProvider>();
      
      bool success = await auth.register(
        username: _username,
        email: _email,
        password: _password,
        confirmedPassword: _confirmPassword,
        fullName: _fullName,
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        if (!mounted) return;
        _showStyledSnackBar('Đăng ký thành công! Vui lòng kiểm tra mã OTP trong email.', isError: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: _email),
          ),
        );
      } else {
        if (!mounted) return;
        _showStyledSnackBar('Đăng ký thất bại, email hoặc tên đăng nhập có thể đã tồn tại!', isError: true);
      }
    }
  }

  void _showStyledSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Decorative Shapes
          Positioned(
            top: -50,
            left: -50,
            child: _buildCircle(200, AppColors.primary.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _buildCircle(250, Colors.blue.withValues(alpha: 0.05)),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bắt đầu hành trình chinh phục tiếng Nhật cùng NihonGo! ngay hôm nay.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  
                  // Registration Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildModernField(
                            label: 'Tên đăng nhập',
                            hint: 'username123',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                            onSaved: (v) => _username = v!,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildModernField(
                            label: 'Họ và tên',
                            hint: 'Nguyễn Văn A',
                            icon: Icons.badge_outlined,
                            validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                            onSaved: (v) => _fullName = v!,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildModernField(
                            label: 'Email',
                            hint: 'example@email.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => !v!.contains('@') ? 'Email không hợp lệ' : null,
                            onSaved: (v) => _email = v!,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildModernField(
                            label: 'Mật khẩu',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
                              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(v)) {
                                return 'Cần có chữ hoa, chữ thường và số';
                              }
                              return null;
                            },
                            onSaved: (v) => _password = v!,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildModernField(
                            label: 'Xác nhận mật khẩu',
                            hint: '••••••••',
                            icon: Icons.lock_reset_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v!.isEmpty ? 'Vui lòng xác nhận mật khẩu' : null,
                            onSaved: (v) => _confirmPassword = v!,
                          ),
                          const SizedBox(height: 32),
                          
                          _isLoading 
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 8,
                                      shadowColor: AppColors.primary.withOpacity(0.3),
                                    ),
                                    child: const Text(
                                      'ĐĂNG KÝ TÀI KHOẢN',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản?', style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đăng nhập', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildModernField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }
}
