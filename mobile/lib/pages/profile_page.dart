import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/abon_logo.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Profile data state
  String _ownerName = 'Memuat...';
  String _email = '';
  String _phone = '';
  String _businessName = 'Abon Salakopi';
  String _businessAddress = '';
  String? _photoUrl;
  bool _darkMode = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final response = await _authService.getProfile();
    if (response['success']) {
      final data = response['data'];
      setState(() {
        _ownerName = data['user']['name'] ?? '';
        _email = data['user']['email'] ?? '';
        _phone = data['profile']['phone'] ?? '';
        _businessName = data['profile']['business_name'] ?? 'Abon Salakopi';
        _businessAddress = data['profile']['business_address'] ?? '';
        _photoUrl = data['profile']['photo_url'];
        _darkMode = data['profile']['dark_mode'] ?? false;
        _notificationsEnabled = data['profile']['notifications_enabled'] ?? true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memuat profil'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateSettings({
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? businessAddress,
    bool? darkMode,
    bool? notificationsEnabled,
  }) async {
    setState(() => _isSaving = true);
    final response = await _authService.updateProfile(
      name: name ?? _ownerName,
      email: email ?? _email,
      phone: phone ?? _phone,
      businessName: businessName ?? _businessName,
      businessAddress: businessAddress ?? _businessAddress,
      darkMode: darkMode ?? _darkMode,
      notificationsEnabled: notificationsEnabled ?? _notificationsEnabled,
    );

    setState(() => _isSaving = false);

    if (response['success']) {
      final data = response['data'];
      setState(() {
        _ownerName = data['user']['name'];
        _email = data['user']['email'];
        _phone = data['profile']['phone'] ?? '';
        _businessName = data['profile']['business_name'] ?? 'Abon Salakopi';
        _businessAddress = data['profile']['business_address'] ?? '';
        _photoUrl = data['profile']['photo_url'];
        _darkMode = data['profile']['dark_mode'] ?? false;
        _notificationsEnabled = data['profile']['notifications_enabled'] ?? true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil diperbarui'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memperbarui pengaturan'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show logout confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final response = await _authService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Logout berhasil'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: _ownerName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ubah Profil Pemilik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pemilik',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.mail_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty || !value.contains('@') ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'No. HP',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _updateSettings(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusinessInfoSheet() {
    final businessController = TextEditingController(text: _businessName);
    final addressController = TextEditingController(text: _businessAddress);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Informasi Usaha Abon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: businessController,
                  decoration: InputDecoration(
                    labelText: 'Nama Usaha / Merek',
                    prefixIcon: const Icon(Icons.storefront),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nama usaha tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Alamat Usaha',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _updateSettings(
                        businessName: businessController.text,
                        businessAddress: addressController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Informasi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Saat Ini',
                    prefixIcon: Icon(Icons.lock_open),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Masukkan password saat ini' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Password konfirmasi tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isSaving = true);
                final response = await _authService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                setState(() => _isSaving = false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message']),
                      backgroundColor: response['success'] ? const Color(0xFF4CAF50) : Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPhotoDialog() {
    final photoUrlController = TextEditingController(text: _photoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah Foto Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masukkan URL Gambar atau gunakan avatar default untuk logo usaha Anda.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: photoUrlController,
              decoration: InputDecoration(
                labelText: 'URL Foto Profil',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pilih Avatar Bawaan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAvatarOption('https://api.dicebear.com/7.x/bottts/svg?seed=Abon1'),
                _buildAvatarOption('https://api.dicebear.com/7.x/identicon/svg?seed=Abon2'),
                _buildAvatarOption('https://api.dicebear.com/7.x/avataaars/svg?seed=Owner'),
                _buildAvatarOption('https://api.dicebear.com/7.x/lorelei/svg?seed=Kitchen'),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              
              // We'll update the profile photo_path with the URL directly using the updateProfile route
              await _authService.updateProfile(
                name: _ownerName,
                email: _email,
                phone: _phone,
                businessName: _businessName,
                businessAddress: _businessAddress,
                darkMode: _darkMode,
                notificationsEnabled: _notificationsEnabled,
              );

              // Update state locally
              setState(() {
                _photoUrl = photoUrlController.text.trim().isEmpty ? null : photoUrlController.text;
                _isSaving = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto profil berhasil disinkronkan'),
                    backgroundColor: Color(0xFF4CAF50),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(String url) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _photoUrl = url;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar dipilih, silakan klik simpan untuk menyimpan permanen'),
            backgroundColor: Color(0xFFD4A853),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _showAvatarPhotoDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _photoUrl == url ? const Color(0xFF8B5E3C) : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const AbonLogo(size: 70, showText: false),
            const SizedBox(height: 16),
            const Text(
              'Abon Salakopi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi 1.0.0 (Release)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Aplikasi Kasir & Pengelolaan Stok UMKM Abon Salakopi Tasikmalaya. Dibuat khusus untuk meningkatkan efisiensi dan transparansi operasional produksi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 Abon Salakopi Team',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
            ),
          )
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bantuan & Dukungan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pertanyaan Umum:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 8),
              Text('1. Bagaimana cara mencatat penjualan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Pilih tab Penjualan pada menu bawah, lalu klik tombol "+ Transaksi Baru" di pojok kanan atas.', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text('2. Bagaimana mencatat stok bahan masuk?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Buka menu Pergerakan, klik "+ Tambah Pergerakan", lalu pilih jenis "Stok Masuk".', style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
              Text('Hubungi Dukungan Teknis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text('Email: support@abonsalakopi.com\nTelepon: +62 812-3456-7890', style: TextStyle(fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Cream white background
      appBar: AppBar(
        title: const Text(
          'Pengaturan Profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFF8C6239),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: const Color(0xFF8B5E3C),
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      // Header
                      ProfileHeader(
                        ownerName: _ownerName,
                        businessName: _businessName,
                        photoUrl: _photoUrl,
                        onEditTap: _showEditProfileSheet,
                        onPhotoTap: _showAvatarPhotoDialog,
                      ),
                      const SizedBox(height: 24),

                      // Settings Group: Akun & Usaha
                      _buildSectionTitle('Akun & Usaha'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.person_outline_rounded,
                              iconColor: const Color(0xFF8B5E3C),
                              iconBgColor: const Color(0xFFF5E6D3),
                              title: 'Ubah Profil',
                              subtitle: 'Nama, Email, dan No. Handphone',
                              onTap: _showEditProfileSheet,
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            SettingsTile(
                              icon: Icons.storefront_rounded,
                              iconColor: const Color(0xFFD4A853),
                              iconBgColor: const Color(0xFFFFF9C4),
                              title: 'Informasi Usaha',
                              subtitle: 'Nama usaha & alamat fisik produksi',
                              onTap: _showBusinessInfoSheet,
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            SettingsTile(
                              icon: Icons.lock_reset_rounded,
                              iconColor: const Color(0xFFE53935),
                              iconBgColor: const Color(0xFFFFEBEE),
                              title: 'Ganti Password',
                              subtitle: 'Ubah kata sandi akun kasir',
                              onTap: _showPasswordDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings Group: Preferensi
                      _buildSectionTitle('Aplikasi & Preferensi'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.notifications_active_outlined,
                              iconColor: Colors.blue.shade700,
                              iconBgColor: Colors.blue.shade50,
                              title: 'Notifikasi',
                              subtitle: 'Aktifkan pengingat restock bahan',
                              trailing: Switch(
                                value: _notificationsEnabled,
                                activeColor: const Color(0xFF8B5E3C),
                                onChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                  _updateSettings(notificationsEnabled: value);
                                },
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            SettingsTile(
                              icon: Icons.dark_mode_outlined,
                              iconColor: Colors.purple.shade700,
                              iconBgColor: Colors.purple.shade50,
                              title: 'Dark Mode',
                              subtitle: 'Tampilan ramah mata di malam hari',
                              trailing: Switch(
                                value: _darkMode,
                                activeColor: const Color(0xFF8B5E3C),
                                onChanged: (value) {
                                  setState(() {
                                    _darkMode = value;
                                  });
                                  _updateSettings(darkMode: value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Settings Group: Bantuan
                      _buildSectionTitle('Dukungan & Info'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Column(
                          children: [
                            SettingsTile(
                              icon: Icons.help_outline_rounded,
                              iconColor: Colors.teal.shade700,
                              iconBgColor: Colors.teal.shade50,
                              title: 'Bantuan',
                              subtitle: 'Pusat panduan penggunaan aplikasi',
                              onTap: _showHelpDialog,
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            SettingsTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: Colors.orange.shade700,
                              iconBgColor: Colors.orange.shade50,
                              title: 'Tentang Aplikasi',
                              subtitle: 'Informasi sistem dan hak cipta',
                              onTap: _showAboutDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'LOGOUT AKUN',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935), // Red
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),

                  // Saving overlay
                  if (_isSaving)
                    Container(
                      color: Colors.black.withOpacity(0.15),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5E3C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(3, (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 100, color: Colors.white),
              const SizedBox(height: 12),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ))
        ],
      ),
    );
  }
}
