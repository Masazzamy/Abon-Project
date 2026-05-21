import 'package:flutter/material.dart';
import 'theme.dart';
import 'dashboard_page.dart';

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
          // 1. White Background with Premium Golden Brown Accents
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
                            // 3. Header Section (Logo, Welcome Text, Subtitle)
                            const _HeaderSection(),
                            const SizedBox(height: 36),

                            // 4. Login Form Section (Email, Password, Button, Forgot PW)
                            const _LoginForm(),
                            const SizedBox(height: 24),

                            // 5. Footer Section (Register Link)
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

/// Draws soft, elegant golden brown gradient accents on the white background.
class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white, // Primary white background
        child: Stack(
          children: [
            // Top Right Golden Blur Accent
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentGold.withAlpha(51), // 20% opacity -> 51 alpha
                      AppTheme.accentGold.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Left Warm Brown Blur Accent
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBrown.withAlpha(30), // 12% opacity -> 30 alpha
                      AppTheme.primaryBrown.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Header Section containing the centered logo, "Selamat Datang" title, and subtitle.
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
                color: AppTheme.primaryBrown.withAlpha(38), // 15% opacity -> 38 alpha
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.accentGold.withAlpha(25), // 10% opacity -> 25 alpha
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.accentGold.withAlpha(128), // 50% opacity -> 128 alpha
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
            fontSize: 28,
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

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
      });
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
            hintText: 'Masukkan email Anda',
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
            hintText: 'Masukkan password Anda',
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
              child: const Text('Lupa Password?'),
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
                  child: const Text('Login'),
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

/// The Footer Section containing registration link and encrypted secure badge.
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Register Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Belum punya akun? ',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Show info snackbar for registration flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur pendaftaran akun sedang dikembangkan. Silakan hubungi admin.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Daftar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Security Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Sistem Terenkripsi & Aman',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable Custom Text Field component styled according to the brand theme.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            labelText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        TextFormField(
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
            prefixIcon: Icon(
              prefixIcon,
              color: AppTheme.primaryBrown.withAlpha(178), // 70% opacity -> 178 alpha
              size: 20,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
