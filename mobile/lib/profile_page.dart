import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_tile.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dummy business & owner data
  String _ownerName = "Masazzamy";
  String _businessName = "Abon Salakopi";
  String _email = "owner@abonsalakopi.com";
  String _phone = "0812-3456-7890";
  String _address = "Jl. Salakopi Raya No. 45, Sukabumi, Jawa Barat";
  
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  // Controllers for edit fields
  late TextEditingController _nameController;
  late TextEditingController _businessController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _ownerName);
    _businessController = TextEditingController(text: _businessName);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(text: _phone);
    _addressController = TextEditingController(text: _address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Edit Profile / Business Info Modal Bottom Sheet
  void _openEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "Edit Profil & Usaha",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Form Fields
                _buildTextField("Nama Pemilik", _nameController, Icons.person_rounded),
                const SizedBox(height: 14),
                _buildTextField("Nama Usaha", _businessController, Icons.storefront_rounded),
                const SizedBox(height: 14),
                _buildTextField("Email Bisnis", _emailController, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildTextField("No. Telepon", _phoneController, Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildTextField("Alamat Gudang/Toko", _addressController, Icons.location_on_rounded, maxLines: 2),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _ownerName = _nameController.text;
                            _businessName = _businessController.text;
                            _email = _emailController.text;
                            _phone = _phoneController.text;
                            _address = _addressController.text;
                          });
                          Navigator.of(context).pop();
                          _showSuccessSnackbar("Profil berhasil diperbarui!");
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: const Text(
                          "Simpan",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Change Password Modal Bottom Sheet
  void _openChangePasswordModal() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "Ganti Password",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField("Password Lama", oldPasswordController, Icons.lock_open_rounded, obscureText: true),
                const SizedBox(height: 14),
                _buildTextField("Password Baru", newPasswordController, Icons.lock_outline_rounded, obscureText: true),
                const SizedBox(height: 14),
                _buildTextField("Konfirmasi Password Baru", confirmPasswordController, Icons.lock_outline_rounded, obscureText: true),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password baru & konfirmasi tidak cocok!"),
                                backgroundColor: AppColors.alert,
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          _showSuccessSnackbar("Password berhasil diperbarui!");
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: const Text(
                          "Simpan",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Business Info Modal Bottom Sheet
  void _openBusinessInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.storefront_outlined, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Informasi Usaha",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Details
              _buildInfoRow(Icons.storefront_rounded, "Nama Usaha", _businessName),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person_outline_rounded, "Nama Pemilik", _ownerName),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email_outlined, "Email Bisnis", _email),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone_android_rounded, "No. Telepon", _phone),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on_outlined, "Alamat Gudang/Toko", _address),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openEditProfileModal();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                ),
                child: const Text("Edit Informasi Usaha", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Help Guide Bottom Sheet
  void _openHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Pusat Bantuan & Panduan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  children: [
                    _buildHelpTile("Bagaimana cara mencatat transaksi baru?", "Masuk ke tab Penjualan, klik '+ Transaksi Baru', lalu pilih abon, kuantitas, dan klik 'Selesaikan Transaksi'."),
                    _buildHelpTile("Bagaimana cara update stok abon?", "Masuk ke tab Inventaris, klik produk abon yang ingin diedit, lalu klik tombol Edit. Anda juga bisa menambah stok via tab Pergerakan Stok."),
                    _buildHelpTile("Mengapa data dashboard kosong?", "Itu tandanya Anda belum mencatat transaksi apa pun. Anda bisa klik tombol 'Simulasikan Data' di tab Home untuk memuat data pengujian."),
                    _buildHelpTile("Bagaimana cara mengekspor laporan?", "Masuk ke tab Laporan, klik tombol ekspor di pojok kanan atas, lalu pilih format ekspor laporan (Excel/PDF) yang diinginkan."),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessSnackbar("Menghubungi Customer Support via WhatsApp...");
                },
                icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
                label: const Text("Hubungi Admin Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // About App Bottom Sheet
  void _openAboutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Abon Salakopi App",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Versi 1.2.0 (Stable Release)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  "Aplikasi manajemen operasional & Point of Sales (POS) pintar khusus UMKM Makanan Abon Salakopi Sukabumi. Dirancang untuk mempercepat pencatatan transaksi kasir, pelacakan pergerakan stok produksi, dan penyusunan laporan keuangan otomatis.",
                  style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF555555)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  "© 2026 Abon Salakopi. Seluruh Hak Cipta Dilindungi.",
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Logout Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.alert),
              SizedBox(width: 10),
              Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi Abon Salakopi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Back to dashboard
                // To simulate logging out, push to login
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alert,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper helper to build text fields for forms
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData prefixIcon, {
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // Info details display row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Help sub-items list
  Widget _buildHelpTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.grey,
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Profile Header
            ProfileHeader(
              ownerName: _ownerName,
              businessName: _businessName,
              onEditPressed: _openEditProfileModal,
            ),
            
            // 2. Settings Menu List
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "PENGATURAN USAHA & AKUN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Menu Items
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: "Edit Profil",
                    subtitle: "Kelola data pribadi pemilik",
                    onTap: _openEditProfileModal,
                  ),
                  SettingsTile(
                    icon: Icons.storefront_outlined,
                    title: "Informasi Usaha",
                    subtitle: "Ubah nama, email, & alamat toko",
                    onTap: _openBusinessInfoModal,
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: "Ganti Password",
                    subtitle: "Perbarui pengamanan akun kasir",
                    onTap: _openChangePasswordModal,
                  ),
                  
                  const SizedBox(height: 20),
                  const Text(
                    "PREFERENSI & APLIKASI",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: "Notifikasi",
                    subtitle: "Terima info stok menipis harian",
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                        _showSuccessSnackbar(val ? "Notifikasi stok aktif!" : "Notifikasi stok dinonaktifkan.");
                      },
                    ),
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    subtitle: "Mode gelap hemat baterai",
                    trailing: Switch(
                      value: _isDarkMode,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isDarkMode = val;
                        });
                        _showSuccessSnackbar(val ? "Dark Mode diaktifkan!" : "Mode terang diaktifkan.");
                      },
                    ),
                    onTap: () {},
                  ),
                  SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: "Bantuan",
                    subtitle: "Panduan pemakaian & admin CS",
                    onTap: _openHelpModal,
                  ),
                  SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: "Tentang Aplikasi",
                    subtitle: "Info versi & hak cipta UMKM",
                    onTap: _openAboutModal,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 3. Logout Button
                  ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      "Keluar dari Akun",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alert,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      elevation: 2,
                      shadowColor: AppColors.alert.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
