import 'package:flutter/material.dart';
import 'theme.dart';
import 'dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Configure smooth entry animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Background with Waves and Leaf Line-art
          const _BackgroundDecorations(),

          // 2. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.15 : 24.0,
                  vertical: 16.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 3. Header Section (Logo, Welcome Text, Star Divider)
                            const _HeaderSection(),
                            const SizedBox(height: 36),

                            // 4. Login Form Section (Email, Password, Button, Forgot PW)
                            const _LoginForm(),
                            const SizedBox(height: 24),

                            // 5. Footer Section (Register Link Outline Button)
                            const _FooterSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws soft, elegant golden brown waves and leaf line-art dynamically.
class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: _LoginBackgroundPainter(),
        ),
      ),
    );
  }
}

/// CustomPainter to draw premium wave decoration and leaf line-art.
class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // --- TOP LEFT WAVES ---
    // Lighter back wave
    paint.color = const Color(0xFFB37B50).withOpacity(0.15);
    final pathTopBack = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.12, 0, size.height * 0.22)
      ..close();
    canvas.drawPath(pathTopBack, paint);

    // Front brown wave
    paint.color = const Color(0xFF8B5E3C);
    final pathTopFront = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.09, 0, size.height * 0.17)
      ..close();
    canvas.drawPath(pathTopFront, paint);

    // --- BOTTOM RIGHT WAVES ---
    // Lighter back wave
    paint.color = const Color(0xFFB37B50).withOpacity(0.15);
    final pathBottomBack = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.4, size.height)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.88, size.width, size.height * 0.78)
      ..close();
    canvas.drawPath(pathBottomBack, paint);

    // Front brown wave
    paint.color = const Color(0xFF8B5E3C);
    final pathBottomFront = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.91, size.width, size.height * 0.83)
      ..close();
    canvas.drawPath(pathBottomFront, paint);

    // --- DRAW LEAF PATTERNS (Line Art) ---
    final leafPaint = Paint()
      ..color = const Color(0xFF8B5E3C).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top-Right Leaf
    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.15);
    canvas.rotate(0.5);
    _drawLeaf(canvas, leafPaint, 55);
    canvas.restore();

    // Bottom-Left Leaf
    canvas.save();
    canvas.translate(size.width * 0.15, size.height * 0.85);
    canvas.rotate(-2.4);
    _drawLeaf(canvas, leafPaint, 60);
    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, Paint paint, double length) {
    // Stem
    final stem = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.2, -length * 0.4, length, -length);
    canvas.drawPath(stem, paint);

    // Leaf 1 (Left side)
    final leafLeft = Path()
      ..moveTo(length * 0.25, -length * 0.25)
      ..quadraticBezierTo(length * 0.1, -length * 0.45, length * 0.35, -length * 0.55)
      ..quadraticBezierTo(length * 0.5, -length * 0.4, length * 0.25, -length * 0.25);
    canvas.drawPath(leafLeft, paint);

    // Leaf 2 (Right side)
    final leafRight = Path()
      ..moveTo(length * 0.4, -length * 0.4)
      ..quadraticBezierTo(length * 0.55, -length * 0.3, length * 0.65, -length * 0.5)
      ..quadraticBezierTo(length * 0.5, -length * 0.6, length * 0.4, -length * 0.4);
    canvas.drawPath(leafRight, paint);

    // Leaf 3 (Tip)
    final leafTip = Path()
      ..moveTo(length * 0.7, -length * 0.7)
      ..quadraticBezierTo(length * 0.75, -length * 0.85, length * 0.95, -length * 0.95)
      ..quadraticBezierTo(length * 0.85, -length * 0.75, length * 0.7, -length * 0.7);
    canvas.drawPath(leafTip, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The Header Section containing the centered logo, "Selamat Datang" title, and diamond divider.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Container with Gold-Brown Shadow & Border
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.accentGold.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.accentGold.withOpacity(0.5),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback elegant icon in case the image fails to load
                return Container(
                  color: AppTheme.primaryBrown,
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Title: Selamat Datang
        const Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBrownDark,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle: Masuk untuk mengelola usaha abon Anda
        const Text(
          'Masuk untuk mengelola usaha abon Anda',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Elegant Star Divider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 40, right: 10),
                height: 1,
                color: AppTheme.accentGold.withOpacity(0.4),
              ),
            ),
            const Text(
              '✦',
              style: TextStyle(
                color: AppTheme.accentGold,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 40),
                height: 1,
                color: AppTheme.accentGold.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Form Widget handling Email, Password inputs, Forgot Password link, and Login Button.
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Alamat IP server backend aktif
        const String localIp = '10.178.53.182'; 
        
        String baseUrl;
        if (kIsWeb) {
          baseUrl = 'http://localhost:8000/api';
        } else {
          baseUrl = 'http://$localIp:8000/api';
        }

        final url = Uri.parse('$baseUrl/login');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            // Show elegant success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                elevation: 4,
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Berhasil Masuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Selamat datang kembali di sistem Abon Salakopi!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Navigate to Dashboard Page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardPage(),
              ),
            );
          }
        } else {
          final responseData = jsonDecode(response.body);
          final String errorMessage = responseData['message'] ?? 'Email atau Password salah.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                elevation: 4,
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppTheme.errorRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Gagal Masuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            errorMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 4,
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kesalahan Koneksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Gagal menghubungi server: $e',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email TextField
          _CustomTextField(
            labelText: 'Email',
            hintText: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Password TextField
          _CustomTextField(
            labelText: 'Password',
            hintText: 'Password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            enabled: !_isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : () => _showForgotPasswordDialog(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lupa Password?',
                style: TextStyle(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Full Width Login Button with Loading Indicator
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBrown),
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.login_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  /// Displays the elegant Dialog when the user clicks 'Forgot Password?'.
  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text);
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Lupa Password',
            style: TextStyle(
              color: AppTheme.primaryBrownDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan email terdaftar untuk menerima tautan pemulihan password.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailResetController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Karyawan',
                    hintText: 'nama@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 45),
                backgroundColor: AppTheme.primaryBrown,
              ),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primaryBrownDark,
                      content: Text(
                        'Tautan pemulihan password telah dikirim ke ${emailResetController.text}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }
}

/// The Footer Section containing centered registration card.
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 'atau' divider
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 10, right: 15),
                height: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            Text(
              'atau',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 15, right: 10),
                height: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Outline container for "Belum punya akun? Daftar"
        GestureDetector(
          onTap: () {
            // Show info snackbar for registration flow
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Fitur pendaftaran akun sedang dikembangkan. Silakan hubungi admin.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Belum punya akun? ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable Custom Text Field component styled with a light cream background and soft border.
class _CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.labelText,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.6),
          fontSize: 15,
        ),
        fillColor: const Color(0xFFFCF8F5), // Soft cream/beige background
        filled: true,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.primaryBrown.withOpacity(0.7),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryBrown,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.errorRed,
            width: 1,
          ),
        ),
      ),
    );
  }
}
