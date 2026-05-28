import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  Map<String, dynamic>? _userLocalData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final localUser = await _authService.getLocalUser();
    setState(() {
      _userLocalData = localUser;
    });

    // Refresh user data from server
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    final result = await _authService.getUser();
    if (result['success']) {
      setState(() {
        _userLocalData = result['data'];
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    final result = await _authService.logout();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'owner':
        return const Color(0xFFFF5722);
      case 'staff':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userLocalData?['name'] ?? 'Loading...';
    final userEmail = _userLocalData?['email'] ?? 'Loading...';
    final userRole = _userLocalData?['role'] ?? 'staff';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Abon Kitchen'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshUserData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Selamat Datang
            Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _getRoleColor(userRole).withOpacity(0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: _getRoleColor(userRole),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badge Role
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(userRole).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getRoleColor(userRole).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        userRole.toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(userRole),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Menu Aplikasi UMKM',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Item-item dummy menu UMKM Abon
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Kelola Produk',
                    color: Colors.amber.shade800,
                  ),
                  _buildMenuCard(
                    icon: Icons.analytics_outlined,
                    title: 'Laporan Penjualan',
                    color: Colors.teal.shade700,
                  ),
                  _buildMenuCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Kelola Staf',
                    color: Colors.purple.shade700,
                  ),
                  _buildMenuCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Stok Bahan Baku',
                    color: Colors.indigo.shade700,
                  ),
                ],
              ),
            ),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'LOGOUT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fitur $title akan segera hadir!'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
