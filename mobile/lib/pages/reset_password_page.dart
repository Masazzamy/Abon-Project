import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  double _strengthScore = 0.0;
  String _strengthLabel = 'Sangat Lemah';
  Color _strengthColor = AppColors.alert;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _strengthScore = 0.0;
        _strengthLabel = 'Sangat Lemah';
        _strengthColor = AppColors.alert;
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
      _strengthScore = score / 5.0;
      if (score <= 2) {
        _strengthLabel = 'Lemah';
        _strengthColor = AppColors.alert;
      } else if (score <= 4) {
        _strengthLabel = 'Sedang';
        _strengthColor = AppColors.warning;
      } else {
        _strengthLabel = 'Kuat';
        _strengthColor = AppColors.success;
      }
    });
  }

  Future<void> _simpanPasswordBaru() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call to reset password
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Password Berhasil Diubah!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Silakan login kembali menggunakan password baru Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ke Halaman Login'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat Password Baru 🔒',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pastikan password baru Anda aman dan mudah diingat.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 28),

              // Password Baru Field
              TextFormField(
                controller: _passwordController,
                obscureText: _isObscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
                    onPressed: () => setState(() => _isObscureNew = !_isObscureNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Strength Indicator UI
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _strengthScore,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _strengthLabel,
                    style: TextStyle(color: _strengthColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Konfirmasi Password Baru Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textGrey),
                    onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _simpanPasswordBaru,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Password Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
