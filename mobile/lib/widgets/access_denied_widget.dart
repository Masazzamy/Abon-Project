import 'package:flutter/material.dart';
import '../app_colors.dart';

class AccessDeniedWidget extends StatelessWidget {
  final String currentRole;
  final List<String> allowedRoles;
  final VoidCallback? onBackToHome;

  const AccessDeniedWidget({
    super.key,
    required this.currentRole,
    required this.allowedRoles,
    this.onBackToHome,
  });

  String _getRoleLabel(String roleId) {
    switch (roleId.toLowerCase()) {
      case 'ceo':
        return 'CEO / Pemilik Usaha';
      case 'manager':
        return 'Manajer';
      case 'admin':
        return 'Admin';
      case 'cashier':
        return 'Kasir';
      case 'warehouse':
        return 'Staff Gudang';
      case 'employee':
        return 'Karyawan';
      default:
        return 'Pengguna';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header with circular alert style
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.alert,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Akses Dibatasi 🔐',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Jabatan Anda saat ini adalah ${_getRoleLabel(currentRole)}.\nAnda tidak memiliki izin untuk mengakses menu ini.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                // Allowed roles list
                const Text(
                  'Menu ini hanya dapat diakses oleh:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: allowedRoles.map((role) {
                    return Chip(
                      backgroundColor: AppColors.secondary,
                      side: BorderSide.none,
                      label: Text(
                        _getRoleLabel(role),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                // Action back button
                if (onBackToHome != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onBackToHome,
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text(
                        'Kembali ke Home',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
