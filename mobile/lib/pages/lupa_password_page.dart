import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import 'login_page.dart';
import 'reset_password_page.dart'; // import page reset password baru

class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key});

  @override
  State<LupaPasswordPage> createState() => _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  
  // Timer settings
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _kirimLinkReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate sending email api call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isSent = true;
    });

    _startTimer();
  }

  Future<void> _bukaGmail() async {
    final Uri gmailUri = Uri.parse('googlegmail://');
    final Uri webGmailUri = Uri.parse('https://gmail.com');
    
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri);
    } else {
      await launchUrl(webGmailUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _bukaEmailDefault() async {
    final Uri mailtoUri = Uri.parse('mailto:');
    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isSent ? _buildSuccessState() : _buildFormState(),
    );
  }

  // STEP 1 - Form State
  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFFA06F4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lupa Password?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                  const Text(
                  'Masukkan email Anda untuk menerima link reset password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xDDFFFFFF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Akun',
                      prefixIcon: Icon(Icons.email_rounded, color: AppColors.primary),
                      hintText: 'Masukkan email akun Anda',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Link reset password akan dikirim ke email yang terdaftar. Periksa folder Spam jika tidak muncul di Inbox.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _kirimLinkReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim Link Reset',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Return to Login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2 - Success State
  Widget _buildSuccessState() {
    final email = _emailController.text;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            // Success icon animation/display
            const Center(
              child: Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.success,
                size: 88,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Email Terkirim! 📧',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Link reset password telah dikirim ke:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            // Email box card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Instructions
            const Text(
              'Instruksi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _buildInstructionRow('1', 'Buka aplikasi Gmail atau Email Anda.'),
            _buildInstructionRow('2', 'Cari email dari Abon Salakopi.'),
            _buildInstructionRow('3', 'Klik tombol atau link "Reset Password".'),
            _buildInstructionRow('4', 'Buat password baru Anda.'),
            const SizedBox(height: 36),

            // Open Gmail Button
            ElevatedButton.icon(
              onPressed: _bukaGmail,
              icon: const Icon(Icons.email_outlined, color: Colors.white),
              label: const Text('Buka Aplikasi Gmail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335), // Gmail Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Open default email client
            OutlinedButton.icon(
              onPressed: _bukaEmailDefault,
              icon: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
              label: const Text('Buka Email Lain'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Countdown timer or Resend link
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _kirimLinkReset,
                      child: const Text(
                        'Kirim Ulang Email',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      'Tidak menerima email? Kirim ulang dalam 00:${_countdown.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
            ),
            const SizedBox(height: 16),

            // Shortcut button to Reset Password Page directly (for testing/deep-link mock)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResetPasswordPage(token: 'mock-reset-token'),
                  ),
                );
              },
              icon: const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.primary),
              label: const Text(
                'Simulasi Buka Link Reset Email',
                style: TextStyle(color: AppColors.primary, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),

            // Back to Login
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Kembali ke Login',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
