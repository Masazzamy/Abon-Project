import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/abon_logo.dart';
import '../app_colors.dart';
import '../providers/user_provider.dart';
import 'dashboard_page.dart';
import 'daftar_page.dart';
import 'lupa_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isObscure = true;
  String _currentBaseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBaseUrl() async {
    final url = await AuthService.getBaseUrl();
    setState(() {
      _currentBaseUrl = url;
    });
  }

  Future<void> _changeBaseUrlDialog() async {
    final controller = TextEditingController(text: _currentBaseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ganti Base URL API'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sesuaikan IP address backend Laravel Anda.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL API',
                  hintText: 'http://10.175.124.237:8000/api',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AuthService.resetBaseUrl();
                final defaultUrl = await AuthService.getBaseUrl();
                setState(() {
                  _currentBaseUrl = defaultUrl;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API URL di-reset ke default launcher')),
                  );
                }
              },
              child: const Text('Reset Default', style: TextStyle(color: AppColors.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService.setBaseUrl(controller.text);
                setState(() {
                  _currentBaseUrl = controller.text;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API URL diubah ke: ${controller.text}')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        // Sync user data to UserProvider
        final userData = result['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          await Provider.of<UserProvider>(context, listen: false)
              .syncFromBackend(userData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    final response = await _authService.pingServer();
    
    if (mounted) {
      Navigator.pop(context); // Close loading indicator
      
      if (response['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text('Koneksi Sukses', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              '${response['message']}\n\nWaktu Server: ${response['time']}',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_rounded, color: AppColors.alert, size: 28),
                SizedBox(width: 8),
                Text('Koneksi Gagal', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response['message'] ?? 'Tidak dapat terhubung ke server Laravel.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Langkah Solusi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Hubungkan HP Android dan Laptop ke jaringan Wi-Fi/Hotspot yang SAMA.\n'
                  '2. Jalankan project lewat file "start_project.bat" di folder root.\n'
                  '3. Pastikan Windows Firewall Anda mengizinkan port 8000.',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.45),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AbonLogo(size: 90),
                  const SizedBox(height: 48),

                  // Email Input Card
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      hintText: 'nama@email.com',
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
                  const SizedBox(height: 18),

                  // Password Input Card
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Lupa Password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LupaPasswordPage()),
                        );
                      },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'MASUK KE APLIKASI',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Go to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Belum punya akun? ",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DaftarPage()),
                          );
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Config API Server Address
                  OutlinedButton.icon(
                    onPressed: _changeBaseUrlDialog,
                    icon: const Icon(Icons.dns_outlined, size: 16),
                    label: Text(
                      'API Base URL: $_currentBaseUrl',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textGrey,
                      side: const BorderSide(color: AppColors.borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.wifi_find_rounded, size: 16),
                    label: const Text('TEST KONEKSI SERVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
