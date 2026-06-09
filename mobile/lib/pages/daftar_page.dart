import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/register_model.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';
import '../providers/user_provider.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Akun, 1: Kedudukan, 2: Konfirmasi, 3: Sukses
  bool _isLoading = false;

  final RegisterModel _registerModel = RegisterModel();
  final AuthService _authService = AuthService();

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _waController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // States
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _setujuSyarat = false;

  // Password Strength
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Sangat Lemah';
  Color _passwordStrengthColor = AppColors.alert;

  final ImagePicker _picker = ImagePicker();

  // Roles Metadata
  final List<Map<String, dynamic>> _kedudukanList = [
    {
      'id': 'ceo',
      'title': 'CEO / Pemilik Usaha',
      'icon': Icons.workspace_premium_rounded,
      'desc': 'Akses penuh semua fitur, laporan keuangan, & kelola pengguna.',
    },
    {
      'id': 'manager',
      'title': 'Manajer',
      'icon': Icons.assessment_rounded,
      'desc': 'Akses laporan & inventaris, kelola karyawan & penjualan.',
    },
    {
      'id': 'admin',
      'title': 'Admin',
      'icon': Icons.manage_accounts_rounded,
      'desc': 'Input data penjualan & stok, lihat laporan terbatas.',
    },
    {
      'id': 'cashier',
      'title': 'Kasir',
      'icon': Icons.point_of_sale_rounded,
      'desc': 'Hanya akses menu Penjualan, catat transaksi & cetak struk.',
    },
    {
      'id': 'warehouse',
      'title': 'Staff Gudang',
      'icon': Icons.inventory_2_rounded,
      'desc': 'Hanya akses Inventaris & Pergerakan, catat stok masuk/keluar.',
    },
    {
      'id': 'employee',
      'title': 'Karyawan',
      'icon': Icons.people_alt_rounded,
      'desc': 'Akses terbatas sesuai tugas, lihat tugas & jadwal saja.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evaluatePasswordStrength);
    _confirmPasswordController.addListener(() => setState(() {}));
    _waController.addListener(_formatWhatsappNumber);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _waController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _formatWhatsappNumber() {
    String text = _waController.text;
    if (text.startsWith('0')) {
      text = text.substring(1);
      _waController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _evaluatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = 'Sangat Lemah';
        _passwordStrengthColor = AppColors.alert;
      });
      return;
    }

    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    setState(() {
      double strength = 0.0;
      if (password.length >= 4) strength += 0.2;
      if (password.length >= 8) strength += 0.3;
      if (hasLetter && hasNumber) strength += 0.3;
      if (hasSpecial) strength += 0.2;

      _passwordStrength = strength;

      if (strength < 0.5) {
        _passwordStrengthLabel = 'Lemah';
        _passwordStrengthColor = AppColors.alert;
      } else if (strength < 0.8) {
        _passwordStrengthLabel = 'Sedang';
        _passwordStrengthColor = AppColors.warning;
      } else {
        _passwordStrengthLabel = 'Kuat';
        _passwordStrengthColor = AppColors.success;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file != null) {
        setState(() {
          _registerModel.fotoProfil = file.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      _registerModel.namaLengkap = _namaController.text.trim();
      _registerModel.noWhatsapp = '+62${_waController.text.trim()}';
      _registerModel.email = _emailController.text.trim();
      _registerModel.password = _passwordController.text;
    } else if (_currentStep == 1) {
      if (_registerModel.kedudukan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus memilih salah satu Kedudukan.'),
            backgroundColor: AppColors.alert,
          ),
        );
        return;
      }
      if (!_setujuSyarat) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus menyetujui Syarat & Ketentuan.'),
            backgroundColor: AppColors.alert,
          ),
        );
        return;
      }
      _registerModel.setujuSyarat = _setujuSyarat;
    }

    setState(() {
      _currentStep++;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final response = await _authService.register(_registerModel);

    setState(() => _isLoading = false);

    if (response['success']) {
      // Sync registered user to provider
      if (response['user'] != null) {
        await Provider.of<UserProvider>(context, listen: false)
            .syncFromBackend(response['user']);
      }
      setState(() {
        _currentStep = 3;
      });
      _pageController.jumpToPage(3);
    } else {
      String errMsg = response['message'] ?? 'Pendaftaran gagal';
      if (response['errors'] != null && response['errors'] is Map) {
        final errors = response['errors'] as Map;
        final listErrors = [];
        errors.forEach((key, value) {
          if (value is List) {
            listErrors.addAll(value);
          } else {
            listErrors.add(value.toString());
          }
        });
        if (listErrors.isNotEmpty) {
          errMsg = listErrors.join('\n');
        }
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pendaftaran Gagal'),
            content: Text(errMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _openSyaratBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Syarat & Ketentuan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: const [
                      Text(
                        '1. Ketentuan Penggunaan',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aplikasi Abon Salakopi disediakan sebagai platform pengelolaan penjualan dan inventaris bagi pelaku usaha UMKM. Anda bertanggung jawab penuh untuk menjaga keamanan password dan data akun Anda.',
                        style: TextStyle(color: AppColors.textDark, height: 1.6),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '2. Privasi Data',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kami mengumpulkan informasi pendaftaran seperti email, nomor WhatsApp, dan data operasional usaha Anda demi mengoptimalkan layanan kami. Kami berkomitmen untuk melindungi data pribadi Anda dan tidak akan membagikannya ke pihak ketiga tanpa izin.',
                        style: TextStyle(color: AppColors.textDark, height: 1.6),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '3. Keamanan Akun',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Anda dilarang keras membagikan kredensial login kepada pihak mana pun demi menghindari penyalahgunaan data stok dan penjualan usaha Anda. Pihak Abon Salakopi tidak bertanggung jawab atas segala kerugian akibat kelalaian kredensial akun.',
                        style: TextStyle(color: AppColors.textDark, height: 1.6),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _setujuSyarat = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Saya Mengerti & Setuju'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0 && _currentStep < 3) {
          _prevStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _currentStep == 3
            ? _buildSuksesPage()
            : Column(
                children: [
                  _buildHeaderSection(),
                  _buildStepIndicator(),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1AkunForm(),
                            _buildStep2KedudukanForm(),
                            _buildStep3Konfirmasi(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _currentStep == 3
            ? null
            : _buildBottomNavigationButtons(),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (_currentStep > 0) {
                    _prevStep();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              const Expanded(child: SizedBox()),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const ClipOval(
                  child: Icon(Icons.rice_bowl_rounded, color: AppColors.primary, size: 28),
                ),
              ),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 48),
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
          const Text(
            'Bergabung dan kelola usaha Abon Salakopi',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode(0, 'Akun'),
          _buildStepLine(0),
          _buildStepNode(1, 'Kedudukan'),
          _buildStepLine(1),
          _buildStepNode(2, 'Selesai'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive || isDone ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isDone ? AppColors.primary : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone ? AppColors.primary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int index) {
    final isDone = _currentStep > index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          color: isDone ? AppColors.primary : Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildStep1AkunForm() {
    return Form(
      key: _step1FormKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Akun',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    'Isi data akun Anda',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: _registerModel.fotoProfil != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_registerModel.fotoProfil!),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  _namaController.text.isNotEmpty && _namaController.text.length >= 2
                                      ? _namaController.text.substring(0, 2).toUpperCase()
                                      : 'US',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto Profil (Opsional)',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nama Lengkap Field
          _buildFormTextField(
            label: 'Nama Lengkap',
            controller: _namaController,
            icon: Icons.person_rounded,
            placeholder: 'Masukkan nama lengkap',
            onChanged: (val) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama lengkap wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Nomor WhatsApp Field
          _buildFormTextField(
            label: 'Nomor WhatsApp',
            controller: _waController,
            icon: Icons.phone_rounded,
            placeholder: '8xx-xxxx-xxxx',
            keyboardType: TextInputType.phone,
            prefix: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border(right: BorderSide(color: AppColors.borderGrey, width: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇮🇩 +62',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nomor WhatsApp wajib diisi';
              }
              if (value.trim().length < 9) {
                return 'Nomor WhatsApp minimal 9 digit';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildFormTextField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email_rounded,
            placeholder: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              helperText: 'Minimal 8 karakter',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password wajib diisi';
              }
              if (value.length < 8) {
                return 'Password minimal 8 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Password strength progress
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _passwordStrengthLabel,
                style: TextStyle(color: _passwordStrengthColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password',
              prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }
              if (value != _passwordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStep2KedudukanForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Kedudukan Anda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Pilih posisi Anda dalam usaha',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grid 6 Positions
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _kedudukanList.length,
          itemBuilder: (context, index) {
            final item = _kedudukanList[index];
            final isSelected = _registerModel.kedudukan == item['id'];

            return AnimatedScale(
              scale: isSelected ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _registerModel.kedudukan = item['id'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderGrey,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 40,
                            color: isSelected ? AppColors.primary : AppColors.textGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primary : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['desc'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textGrey,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Info Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kedudukan menentukan fitur yang bisa Anda akses dalam aplikasi ini.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Checkbox T&C
        Row(
          children: [
            Checkbox(
              activeColor: AppColors.primary,
              value: _setujuSyarat,
              onChanged: (val) {
                setState(() {
                  _setujuSyarat = val ?? false;
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openSyaratBottomSheet,
                child: const Text.rich(
                  TextSpan(
                    text: 'Saya menyetujui ',
                    style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    children: [
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' Abon Salakopi.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStep3Konfirmasi() {
    // Find role title
    final chosenRole = _kedudukanList.firstWhere(
      (element) => element['id'] == _registerModel.kedudukan,
      orElse: () => {'title': 'CEO / Pemilik Usaha'},
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfirmasi Pendaftaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Tinjau kembali data Anda sebelum mendaftar',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        const Text('INFORMASI AKUN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary, letterSpacing: 0.8)),
        const Divider(),
        _buildReviewRow('Nama Lengkap', _registerModel.namaLengkap),
        _buildReviewRow('WhatsApp', _registerModel.noWhatsapp),
        _buildReviewRow('Email', _registerModel.email),
        const SizedBox(height: 24),

        const Text('KEDUDUKAN JABATAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary, letterSpacing: 0.8)),
        const Divider(),
        _buildReviewRow('Posisi Jabatan', chosenRole['title'] as String),
        const SizedBox(height: 24),

        if (_registerModel.fotoProfil != null) ...[
          const Text('FOTO PROFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary, letterSpacing: 0.8)),
          const Divider(),
          const SizedBox(height: 10),
          Center(
            child: ClipOval(
              child: Image.file(
                File(_registerModel.fotoProfil!),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pastikan nomor WhatsApp dan email Anda aktif agar dapat dihubungi dan menerima notifikasi sistem.',
                  style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildSuksesPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 90),
            ),
            const SizedBox(height: 28),
            const Text(
              'Registrasi Berhasil! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Akun Anda telah berhasil dibuat. Silakan masuk ke dalam dashboard untuk memulai pengelolaan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Text(
                'MASUK KE DASHBOARD',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationButtons() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          if (!isFirstStep) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('KEMBALI'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (isLastStep ? _submitRegistration : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isLastStep ? 'DAFTAR SEKARANG' : 'LANJUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix == null ? Icon(icon, color: AppColors.primary) : null,
        prefix: prefix,
        hintText: placeholder,
      ),
      validator: validator,
    );
  }
}
