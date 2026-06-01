import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_colors.dart';
import 'dashboard_page.dart';

// ═══════════════════════════════════════
// MODEL DATA REGISTRASI
// ═══════════════════════════════════════
class RegisterModel {
  String? fotoProfil;
  String namaLengkap = '';
  String noWhatsapp = '';
  String email = '';
  String password = '';
  bool setujuSyarat = false;
  
  String? fotoUsaha;
  String namaUsaha = '';
  String jenisUsaha = 'Abon Sapi';
  String skalaUsaha = 'Rumahan'; // Rumahan, Kecil, Menengah
  String alamat = '';
  String kota = '';
  String provinsi = 'Jawa Barat';
  String? nomorPirt;
  String? instagram;
  String? whatsappBusiness;
}

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Akun, 1: Usaha, 2: Selesai
  bool _isLoading = false;
  bool _registrationSuccess = false;

  final RegisterModel _formData = RegisterModel();

  // Step 1 Controllers & Focus Nodes
  final _step1FormKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _waController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _namaFocusNode = FocusNode();
  final _waFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Step 2 Controllers & Focus Nodes
  final _step2FormKey = GlobalKey<FormState>();
  final _namaUsahaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _kotaController = TextEditingController();
  final _pirtController = TextEditingController();
  final _instagramController = TextEditingController();
  final _waBizController = TextEditingController();

  final _namaUsahaFocusNode = FocusNode();
  final _alamatFocusNode = FocusNode();
  final _kotaFocusNode = FocusNode();
  final _pirtFocusNode = FocusNode();
  final _instagramFocusNode = FocusNode();
  final _waBizFocusNode = FocusNode();

  // Password Visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Real-time validation states
  bool _isNamaValid = false;
  bool _isWaValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  bool _isNamaUsahaValid = false;
  bool _isAlamatValid = false;
  bool _isKotaValid = false;

  // Debounce helpers for real-time check
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Listeners for real-time validation
    _namaController.addListener(() => _debounceValidation(_validateNamaLengkap));
    _waController.addListener(() => _debounceValidation(_validateWa));
    _emailController.addListener(() => _debounceValidation(_validateEmail));
    _passwordController.addListener(() {
      _debounceValidation(() {
        _validatePassword();
        _validateConfirmPassword();
      });
    });
    _confirmPasswordController.addListener(() => _debounceValidation(_validateConfirmPassword));

    _namaUsahaController.addListener(() => _debounceValidation(_validateNamaUsaha));
    _alamatController.addListener(() => _debounceValidation(_validateAlamat));
    _kotaController.addListener(() => _debounceValidation(_validateKota));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaController.dispose();
    _waController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaFocusNode.dispose();
    _waFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _namaUsahaController.dispose();
    _alamatController.dispose();
    _kotaController.dispose();
    _pirtController.dispose();
    _instagramController.dispose();
    _waBizController.dispose();
    _namaUsahaFocusNode.dispose();
    _alamatFocusNode.dispose();
    _kotaFocusNode.dispose();
    _pirtFocusNode.dispose();
    _instagramFocusNode.dispose();
    _waBizFocusNode.dispose();

    _debounceTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // VALIDASI REAL-TIME
  // ═══════════════════════════════════════
  void _debounceValidation(VoidCallback action) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(action);
      }
    });
  }

  void _validateNamaLengkap() {
    final text = _namaController.text.trim();
    _isNamaValid = text.isNotEmpty && text.length >= 3;
    _formData.namaLengkap = text;
  }

  void _validateWa() {
    final text = _waController.text.trim();
    _isWaValid = text.isNotEmpty && text.length >= 9;
    _formData.noWhatsapp = text;
  }

  void _validateEmail() {
    final text = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    _isEmailValid = text.isNotEmpty && emailRegex.hasMatch(text);
    _formData.email = text;
  }

  void _validatePassword() {
    final text = _passwordController.text;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasDigit = RegExp(r'[0-9]').hasMatch(text);
    _isPasswordValid = text.length >= 8 && hasLetter && hasDigit;
    _formData.password = text;
  }

  void _validateConfirmPassword() {
    final text = _confirmPasswordController.text;
    _isConfirmPasswordValid = text.isNotEmpty && text == _passwordController.text;
  }

  void _validateNamaUsaha() {
    final text = _namaUsahaController.text.trim();
    _isNamaUsahaValid = text.isNotEmpty && text.length >= 3;
    _formData.namaUsaha = text;
  }

  void _validateAlamat() {
    final text = _alamatController.text.trim();
    _isAlamatValid = text.isNotEmpty && text.length >= 5;
    _formData.alamat = text;
  }

  void _validateKota() {
    final text = _kotaController.text.trim();
    _isKotaValid = text.isNotEmpty && text.length >= 3;
    _formData.kota = text;
  }

  // ═══════════════════════════════════════
  // KEKUATAN PASSWORD CALCULATOR
  // ═══════════════════════════════════════
  String _getPasswordStrengthLabel() {
    final text = _passwordController.text;
    if (text.isEmpty) return 'Kosong';
    if (text.length < 6) return 'Lemah';
    
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasDigit = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$&*~]').hasMatch(text);

    if (text.length >= 8 && hasLetter && hasDigit && hasSpecial) return 'Kuat';
    return 'Sedang';
  }

  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrengthLabel();
    if (strength == 'Kuat') return AppColors.success;
    if (strength == 'Sedang') return AppColors.warning;
    if (strength == 'Lemah') return AppColors.alert;
    return Colors.grey[300]!;
  }

  double _getPasswordStrengthPercent() {
    final strength = _getPasswordStrengthLabel();
    if (strength == 'Kuat') return 1.0;
    if (strength == 'Sedang') return 0.66;
    if (strength == 'Lemah') return 0.33;
    return 0.0;
  }

  // ═══════════════════════════════════════
  // IMAGE PICKER SIMULATOR/REAL IMPLEMENTATION
  // ═══════════════════════════════════════
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isProfile) {
            _formData.fotoProfil = image.path;
          } else {
            _formData.fotoUsaha = image.path;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isProfile ? 'Foto profil terpilih!' : 'Foto usaha terpilih!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Graceful fallback for environments where image_picker fails or lacks permissions
      setState(() {
        if (isProfile) {
          _formData.fotoProfil = 'simulated_profile_pic';
        } else {
          _formData.fotoUsaha = 'simulated_usaha_pic';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulasi: ${isProfile ? "Foto profil" : "Logo usaha"} berhasil diunggah!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ═══════════════════════════════════════
  // PROGRESS NAVIGATION HANDLERS
  // ═══════════════════════════════════════
  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate() && _formData.setujuSyarat) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        setState(() {
          _currentStep = 1;
        });
      } else if (!_formData.setujuSyarat) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        setState(() {
          _currentStep = 2;
        });
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _goToStep(int step) {
    if (step < _currentStep) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentStep = step;
      });
    }
  }

  // ═══════════════════════════════════════
  // DAFTAR PROSES FINAL — REAL API
  // ═══════════════════════════════════════
  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sama dengan pola URL di login_page.dart
      const String localIp = '10.155.21.36';
      final String baseUrl = kIsWeb
          ? 'http://localhost:8000/api'
          : 'http://$localIp:8000/api';

      final url = Uri.parse('$baseUrl/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _formData.namaLengkap,
          'email': _formData.email,
          'password': _formData.password,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Pendaftaran sukses
        setState(() {
          _isLoading = false;
          _registrationSuccess = true;
        });
      } else {
        // Error dari server (email duplikat, validasi, dsb)
        final responseData = jsonDecode(response.body);
        String errorMsg = 'Pendaftaran gagal. Silakan coba lagi.';

        // Laravel mengembalikan errors.email[0] untuk validasi
        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMsg = firstError.first.toString();
          }
        } else if (responseData['message'] != null) {
          errorMsg = responseData['message'];
        }

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kesalahan Koneksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Pastikan server backend aktif & terhubung ke jaringan yang sama.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ═══════════════════════════════════════
  // TERMA & KETENTUAN BOTTOM SHEET
  // ═══════════════════════════════════════
  void _openTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SyaratBottomSheet(
          onAgree: () {
            setState(() {
              _formData.setujuSyarat = true;
            });
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Anda menyetujui Syarat & Ketentuan.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // BUILD MAIN UI
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_registrationSuccess) {
      return _SuksesPage(
        namaLengkap: _formData.namaLengkap,
        namaUsaha: _formData.namaUsaha,
        email: _formData.email,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. HEADER SECTION
          _HeaderSection(
            currentStep: _currentStep,
            onBackPressed: () {
              if (_currentStep > 0) {
                _prevStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),

          // 2. STEP INDICATOR
          _StepIndicator(
            currentStep: _currentStep,
            onStepTap: _goToStep,
          ),

          // 3. SCROLLABLE FORM CONTROLLERS AREA
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Force navigation via buttons
              children: [
                // STEP 1 FORM
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Form(
                    key: _step1FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepHeading(
                          icon: Icons.person_outline_rounded,
                          title: 'Informasi Akun',
                          subtitle: 'Isi data untuk masuk ke aplikasi',
                        ),
                        const SizedBox(height: 20),

                        // A. Foto Profil Picker
                        Center(
                          child: _AvatarPicker(
                            fotoProfil: _formData.fotoProfil,
                            namaLengkap: _namaController.text,
                            onTap: () => _pickImage(true),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // B. Nama Lengkap Field
                        _FormTextField(
                          labelText: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap',
                          controller: _namaController,
                          focusNode: _namaFocusNode,
                          nextFocusNode: _waFocusNode,
                          prefixIcon: Icons.person_rounded,
                          isValid: _isNamaValid,
                          validator: (val) {
                            if (val == null || val.trim().length < 3) {
                              return 'Nama minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // C. Nomor WhatsApp Field
                        _FormTextField(
                          labelText: 'Nomor WhatsApp',
                          hintText: '8xx-xxxx-xxxx',
                          controller: _waController,
                          focusNode: _waFocusNode,
                          nextFocusNode: _emailFocusNode,
                          prefixIcon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          isValid: _isWaValid,
                          isPhone: true,
                          helperText: 'Akan digunakan untuk verifikasi akun',
                          validator: (val) {
                            if (val == null || val.trim().length < 9) {
                              return 'Nomor WhatsApp tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // D. Email Field
                        _FormTextField(
                          labelText: 'Email',
                          hintText: 'contoh@email.com',
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          nextFocusNode: _passwordFocusNode,
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          isValid: _isEmailValid,
                          validator: (val) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (val == null || !emailRegex.hasMatch(val.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // E. Password Field
                        _FormTextField(
                          labelText: 'Password',
                          hintText: 'Buat password',
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          nextFocusNode: _confirmPasswordFocusNode,
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          isValid: _isPasswordValid,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.length < 8) {
                              return 'Password minimal 8 karakter dengan huruf & angka';
                            }
                            final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(val);
                            final hasDigit = RegExp(r'[0-9]').hasMatch(val);
                            if (!hasLetter || !hasDigit) {
                              return 'Password harus mengandung huruf & angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // PASSWORD STRENGTH METER & VERIFICATION CHECKLIST
                        _PasswordStrengthBar(
                          strengthLabel: _getPasswordStrengthLabel(),
                          strengthPercent: _getPasswordStrengthPercent(),
                          color: _getPasswordStrengthColor(),
                          passwordText: _passwordController.text,
                        ),
                        const SizedBox(height: 18),

                        // F. Konfirmasi Password Field
                        _FormTextField(
                          labelText: 'Konfirmasi Password',
                          hintText: 'Ulangi password',
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          prefixIcon: Icons.lock_clock_rounded,
                          obscureText: _obscureConfirmPassword,
                          isValid: _isConfirmPasswordValid,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (val != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // G. Syarat & Ketentuan Checkbox Link Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _formData.setujuSyarat,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  _formData.setujuSyarat = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _openTermsSheet,
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Saya menyetujui ',
                                    style: TextStyle(color: Colors.black54, fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Syarat & Ketentuan',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' dan '),
                                      TextSpan(
                                        text: 'Kebijakan Privasi',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // STEP 2 FORM
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Form(
                    key: _step2FormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepHeading(
                          icon: Icons.storefront_outlined,
                          title: 'Informasi Usaha',
                          subtitle: 'Ceritakan tentang usaha Anda',
                        ),
                        const SizedBox(height: 20),

                        // A. Foto/Logo Usaha Picker
                        Center(
                          child: _LogoPicker(
                            fotoUsaha: _formData.fotoUsaha,
                            onTap: () => _pickImage(false),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // B. Nama Usaha Field
                        _FormTextField(
                          labelText: 'Nama Usaha',
                          hintText: 'Contoh: Abon Salakopi',
                          controller: _namaUsahaController,
                          focusNode: _namaUsahaFocusNode,
                          nextFocusNode: _alamatFocusNode,
                          prefixIcon: Icons.store_rounded,
                          isValid: _isNamaUsahaValid,
                          helperText: 'Nama yang akan tampil di aplikasi Anda',
                          validator: (val) {
                            if (val == null || val.trim().length < 3) {
                              return 'Nama usaha minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // C. Jenis Usaha Dropdown Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jenis Usaha',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _formData.jenisUsaha,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.category_rounded, color: AppColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                filled: true,
                                fillColor: const Color(0xFFFCF8F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Abon Sapi', child: Text('Abon Sapi')),
                                DropdownMenuItem(value: 'Abon Ayam', child: Text('Abon Ayam')),
                                DropdownMenuItem(value: 'Abon Ikan', child: Text('Abon Ikan')),
                                DropdownMenuItem(value: 'Abon Campur', child: Text('Abon Campur')),
                                DropdownMenuItem(value: 'Produk Olahan Lainnya', child: Text('Produk Olahan Lainnya')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _formData.jenisUsaha = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // D. Skala Usaha (Card Toggle Single-Select)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Skala Usaha',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            _SkalaUsahaSelector(
                              selectedSkala: _formData.skalaUsaha,
                              onSelect: (val) {
                                setState(() {
                                  _formData.skalaUsaha = val;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // E. Alamat Usaha Field
                        _FormTextField(
                          labelText: 'Alamat Usaha',
                          hintText: 'Jl. Contoh No.1, Kelurahan, Kecamatan, Kota',
                          controller: _alamatController,
                          focusNode: _alamatFocusNode,
                          nextFocusNode: _kotaFocusNode,
                          prefixIcon: Icons.location_on_rounded,
                          isValid: _isAlamatValid,
                          maxLines: 3,
                          validator: (val) {
                            if (val == null || val.trim().length < 5) {
                              return 'Alamat lengkap wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // F. Kota/Kabupaten Field
                        _FormTextField(
                          labelText: 'Kota / Kabupaten',
                          hintText: 'Contoh: Sukabumi',
                          controller: _kotaController,
                          focusNode: _kotaFocusNode,
                          nextFocusNode: _pirtFocusNode,
                          prefixIcon: Icons.location_city_rounded,
                          isValid: _isKotaValid,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Kota/kabupaten wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // G. Provinsi Dropdown Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Provinsi',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _formData.provinsi,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.map_rounded, color: AppColors.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                filled: true,
                                fillColor: const Color(0xFFFCF8F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Jawa Barat', child: Text('Jawa Barat')),
                                DropdownMenuItem(value: 'DKI Jakarta', child: Text('DKI Jakarta')),
                                DropdownMenuItem(value: 'Banten', child: Text('Banten')),
                                DropdownMenuItem(value: 'Jawa Tengah', child: Text('Jawa Tengah')),
                                DropdownMenuItem(value: 'Jawa Timur', child: Text('Jawa Timur')),
                                DropdownMenuItem(value: 'D.I. Yogyakarta', child: Text('D.I. Yogyakarta')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _formData.provinsi = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // H. Nomor PIRT Field (Opsional)
                        _FormTextField(
                          labelText: 'Nomor PIRT (Opsional)',
                          hintText: 'P-IRT 15 digit jika ada',
                          controller: _pirtController,
                          focusNode: _pirtFocusNode,
                          nextFocusNode: _waBizFocusNode,
                          prefixIcon: Icons.verified_rounded,
                          keyboardType: TextInputType.number,
                          helperText: 'Izin Pangan Industri Rumah Tangga',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Apa itu P-IRT?'),
                                  content: const Text(
                                    'P-IRT (Pangan Industri Rumah Tangga) adalah sertifikat izin jaminan keamanan pangan yang dikeluarkan oleh Bupati/Walikota melalui Dinas Kesehatan untuk produk pangan skala rumahan/mikro.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Mengerti', style: TextStyle(color: AppColors.primary)),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // I. Media Sosial Section
                        const Text(
                          'Media Sosial & Kontak Bisnis (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _FormTextField(
                                labelText: 'WhatsApp Bisnis',
                                hintText: '08xx',
                                controller: _waBizController,
                                focusNode: _waBizFocusNode,
                                nextFocusNode: _instagramFocusNode,
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FormTextField(
                                labelText: 'Instagram Usaha',
                                hintText: '@namausaha',
                                controller: _instagramController,
                                focusNode: _instagramFocusNode,
                                prefixIcon: Icons.camera_alt_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // STEP 3 KONFIRMASI REVIEW
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _StepHeading(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Konfirmasi Data',
                        subtitle: 'Periksa kembali sebelum mendaftar',
                      ),
                      const SizedBox(height: 20),

                      // Card 1: Review Akun
                      _ReviewCard(
                        title: 'INFORMASI AKUN',
                        avatar: _formData.fotoProfil,
                        avatarInitials: _formData.namaLengkap.isNotEmpty ? _formData.namaLengkap.substring(0, 1).toUpperCase() : 'M',
                        onEdit: () => _goToStep(0),
                        rows: [
                          _ReviewRow(Icons.person_outline_rounded, 'Nama', _formData.namaLengkap),
                          _ReviewRow(Icons.phone_rounded, 'WhatsApp', '+62 ${_waController.text}'),
                          _ReviewRow(Icons.email_outlined, 'Email', _formData.email),
                          _ReviewRow(Icons.lock_outline_rounded, 'Password', '•••••••• (Aman)'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card 2: Review Usaha
                      _ReviewCard(
                        title: 'INFORMASI USAHA',
                        avatar: _formData.fotoUsaha,
                        isLogo: true,
                        onEdit: () => _goToStep(1),
                        rows: [
                          _ReviewRow(Icons.storefront_rounded, 'Nama Toko', _formData.namaUsaha),
                          _ReviewRow(Icons.category_outlined, 'Jenis Usaha', _formData.jenisUsaha),
                          _ReviewRow(Icons.layers_outlined, 'Skala Usaha', _formData.skalaUsaha),
                          _ReviewRow(Icons.location_on_outlined, 'Alamat', '${_formData.alamat}, ${_formData.kota}, ${_formData.provinsi}'),
                          if (_pirtController.text.isNotEmpty)
                            _ReviewRow(Icons.verified_user_outlined, 'No. PIRT', _pirtController.text),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Notice Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: AppColors.primary, width: 4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Dengan mendaftar, Anda menyetujui seluruh Syarat & Ketentuan penggunaan platform manajemen operasional digital UMKM Abon Salakopi.',
                                style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM NAVIGATION STICKY BUTTON BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: _buildBottomButtons(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_currentStep == 0) {
      final isStep1Valid = _isNamaValid && _isWaValid && _isEmailValid && _isPasswordValid && _isConfirmPasswordValid && _formData.setujuSyarat;
      return ElevatedButton(
        onPressed: isStep1Valid ? _nextStep : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Lanjut ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      );
    } else if (_currentStep == 1) {
      final isStep2Valid = _isNamaUsahaValid && _isAlamatValid && _isKotaValid;
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Kembali', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: isStep2Valid ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Lanjut ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _submitRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Daftar Sekarang ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isLoading ? null : _prevStep,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Kembali', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}

// ═══════════════════════════════════════
// WIDGET WIDGET SUB-COMPONENTS
// ═══════════════════════════════════════

// --- 1. HEADER SECTION ---
class _HeaderSection extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBackPressed;

  const _HeaderSection({
    required this.currentStep,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFFB37B50),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.0),
          bottomRight: Radius.circular(28.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.0, statusBarHeight + 8.0, 16.0, 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: onBackPressed,
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 40), // Spacer for centering
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Buat Akun Baru',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bergabung dan kelola usaha abon Anda',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. STEP INDICATOR ---
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildStep(0, 'Akun'),
          _buildLine(0),
          _buildStep(1, 'Usaha'),
          _buildLine(1),
          _buildStep(2, 'Selesai'),
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, String label) {
    final isDone = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    return GestureDetector(
      onTap: () => onStepTap(stepIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone || isActive ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone || isActive ? AppColors.primary : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : Text(
                      (stepIndex + 1).toString(),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive || isDone ? AppColors.primary : Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLine(int index) {
    final passed = index < currentStep;
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        decoration: BoxDecoration(
          color: passed ? AppColors.primary : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// --- 3. STEP HEADING ---
class _StepHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        )
      ],
    );
  }
}

// --- 4. FORM FIELD COMPONENTS ---
class _FormTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool isValid;
  final bool isPhone;
  final String? helperText;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormTextField({
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.isValid = false,
    this.isPhone = false,
    this.helperText,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          validator: validator,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperStyle: const TextStyle(fontSize: 11),
            prefixIcon: isPhone
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🇮🇩 +62',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      const SizedBox(width: 8),
                    ],
                  )
                : Icon(prefixIcon, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon ??
                (isValid
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                    : null),
            fillColor: const Color(0xFFFCF8F5),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.alert),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 5. PASSWORD STRENGTH BAR ---
class _PasswordStrengthBar extends StatelessWidget {
  final String strengthLabel;
  final double strengthPercent;
  final Color color;
  final String passwordText;

  const _PasswordStrengthBar({
    required this.strengthLabel,
    required this.strengthPercent,
    required this.color,
    required this.passwordText,
  });

  @override
  Widget build(BuildContext context) {
    if (passwordText.isEmpty) return const SizedBox.shrink();

    final hasMinLength = passwordText.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(passwordText);
    final hasDigit = RegExp(r'[0-9]').hasMatch(passwordText);
    final hasSpecial = RegExp(r'[!@#\$&*~]').hasMatch(passwordText);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strengthPercent,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Kekuatan: $strengthLabel',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCheck(hasMinLength, 'Min. 8 Karakter'),
            _buildCheck(hasLetter, 'Ada Huruf'),
            _buildCheck(hasDigit, 'Ada Angka'),
            _buildCheck(hasSpecial, 'Ada Simbol'),
          ],
        )
      ],
    );
  }

  Widget _buildCheck(bool satisfied, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: satisfied ? AppColors.success : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: satisfied ? FontWeight.bold : FontWeight.normal,
            color: satisfied ? AppColors.success : Colors.grey,
          ),
        )
      ],
    );
  }
}

// --- 6. AVATAR PICKER (interactive) ---
class _AvatarPicker extends StatelessWidget {
  final String? fotoProfil;
  final String namaLengkap;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.fotoProfil,
    required this.namaLengkap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = namaLengkap.isNotEmpty ? namaLengkap.trim().substring(0, 1).toUpperCase() : 'A';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFB37B50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: fotoProfil != null
                  ? (fotoProfil!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: fotoProfil!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                        )
                      : (fotoProfil == 'simulated_profile_pic'
                          ? const Center(child: Icon(Icons.person_rounded, size: 50, color: Colors.white))
                          : Image.file(File(fotoProfil!), fit: BoxFit.cover)))
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          )
        ],
      ),
    );
  }
}

// --- 7. LOGO PICKER ---
class _LogoPicker extends StatelessWidget {
  final String? fotoUsaha;
  final VoidCallback onTap;

  const _LogoPicker({
    required this.fotoUsaha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: fotoUsaha != null
                  ? (fotoUsaha == 'simulated_usaha_pic'
                      ? const Center(child: Icon(Icons.storefront_rounded, size: 50, color: AppColors.primary))
                      : Image.file(File(fotoUsaha!), fit: BoxFit.cover))
                  : const Center(
                      child: Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary),
                    ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          )
        ],
      ),
    );
  }
}

// --- 8. SKALA USAHA SELECTOR ---
class _SkalaUsahaSelector extends StatelessWidget {
  final String selectedSkala;
  final Function(String) onSelect;

  const _SkalaUsahaSelector({
    required this.selectedSkala,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard('🏠', 'Rumahan', '1-5 org')),
        const SizedBox(width: 8),
        Expanded(child: _buildCard('🏪', 'Kecil', '5-20 org')),
        const SizedBox(width: 8),
        Expanded(child: _buildCard('🏭', 'Menengah', '20+ org')),
      ],
    );
  }

  Widget _buildCard(String emoji, String title, String description) {
    final isSelected = selectedSkala == title;

    return GestureDetector(
      onTap: () => onSelect(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C2C2C))),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- 9. REVIEW CARD (Step 3 Confirmation) ---
class _ReviewCard extends StatelessWidget {
  final String title;
  final String? avatar;
  final String? avatarInitials;
  final bool isLogo;
  final List<Widget> rows;
  final VoidCallback onEdit;

  const _ReviewCard({
    required this.title,
    this.avatar,
    this.avatarInitials,
    this.isLogo = false,
    required this.rows,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13, letterSpacing: 0.5),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text('Ubah', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Body Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Avatar if Profile or Logo
                if (avatarInitials != null || isLogo) ...[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: ClipOval(
                      child: avatar != null
                          ? (avatar == 'simulated_profile_pic' || avatar == 'simulated_usaha_pic'
                              ? const Icon(Icons.storefront_rounded, color: Colors.white)
                              : Image.file(File(avatar!), fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                avatarInitials ?? 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Details Rows
                Expanded(
                  child: Column(
                    children: rows,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }
}

// --- 10. TERMS BOTTOM SHEET ---
class _SyaratBottomSheet extends StatelessWidget {
  final VoidCallback onAgree;

  const _SyaratBottomSheet({required this.onAgree});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Syarat & Ketentuan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('1. Ketentuan Penggunaan Layanan',
                      'Layanan digital aplikasi manajemen operasional UMKM Abon Salakopi disediakan secara khusus untuk membantu pencatatan data internal, Point of Sales, inventaris stok, serta pelaporan keuangan. Pengguna bertanggung jawab penuh atas keabsahan seluruh data yang didaftarkan ke sistem ini.'),
                  const SizedBox(height: 16),
                  _buildSection('2. Privasi & Keamanan Data Pengguna',
                      'Kami menjaga privasi data pribadi dan bisnis Anda dengan ketat. Seluruh informasi seperti nama, WhatsApp, email, dan detail finansial usaha terenkripsi aman dan tidak akan dibagikan kepada pihak ketiga manapun tanpa persetujuan tertulis.'),
                  const SizedBox(height: 16),
                  _buildSection('3. Tanggung Jawab Keamanan Akun',
                      'Pengguna wajib merahasiakan password akun masing-masing. Seluruh tindakan transaksi atau manipulasi inventaris yang terjadi di bawah akun Anda dianggap sah sebagai otorisasi pemilik usaha.'),
                  const SizedBox(height: 16),
                  _buildSection('4. Penyelesaian Sengketa',
                      'Segala perselisihan atau kegagalan sistem operasional diselesaikan secara kekeluargaan bersama Admin Support UMKM Abon Salakopi.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Footer Button
          ElevatedButton(
            onPressed: onAgree,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Saya Mengerti & Setuju', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
        ),
      ],
    );
  }
}

// --- 11. REGISTRATION SUCCESS PAGE (Dynamic Countdown Redirect) ---
class _SuksesPage extends StatefulWidget {
  final String namaLengkap;
  final String namaUsaha;
  final String email;

  const _SuksesPage({
    required this.namaLengkap,
    required this.namaUsaha,
    required this.email,
  });

  @override
  State<_SuksesPage> createState() => _SuksesPageState();
}

class _SuksesPageState extends State<_SuksesPage> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _redirectToDashboard();
      }
    });
  }

  void _redirectToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Big Premium Success Check Icon with glowing ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 90,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Success Title
                const Text(
                  '🎉 Pendaftaran Berhasil!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Greeting Subtitles
                Text(
                  'Selamat datang, ${widget.namaLengkap}!',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Akun usaha "${widget.namaUsaha}" Anda berhasil dibuat. Mulai kelola usaha abon Anda dengan lebih cerdas & mudah sekarang.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white.withOpacity(0.85)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Summary Receipt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'Ringkasan Akun Baru',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),
                      _buildReceiptRow(Icons.person_rounded, 'Pemilik', widget.namaLengkap),
                      const SizedBox(height: 10),
                      _buildReceiptRow(Icons.storefront_rounded, 'Usaha', widget.namaUsaha),
                      const SizedBox(height: 10),
                      _buildReceiptRow(Icons.email_rounded, 'Email', widget.email),
                    ],
                  ),
                ),
                const Spacer(),

                // CTA Button
                ElevatedButton(
                  onPressed: _redirectToDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Mulai Gunakan Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-redirect text & dynamic loader
                Text(
                  'Mengarahkan otomatis dalam $_countdown detik...',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 140,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: (5 - _countdown) / 5.0,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary.withOpacity(0.8), size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}
