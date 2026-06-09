import 'dart:async';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';
import '../widgets/profil_avatar.dart';
import '../widgets/access_denied_widget.dart';
import '../helpers/waktu_helper.dart';
import '../app_colors.dart';
import 'login_page.dart';
import 'inventaris_page.dart';
import 'penjualan_page.dart';
import 'pergerakan_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';
import 'notifikasi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  bool _isLoading = false;
  int _currentIndex = 0;
  int _unreadCount = 0;

  // Real-time time & date states
  String _timeString = '';
  String _dateString = '';
  Timer? _clockTimer;

  // Local static counts/stats (defaults, can be updated via API sync)
  final String penjualanHariIni = "Rp 0";
  final int jumlahTransaksi = 0;
  final int totalProduk = 0;
  final int stokMenipis = 0;
  final String totalMingguan = "Rp 0";

  @override
  void initState() {
    super.initState();
    _startClock();
    // Delay context-dependent calls until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncUserSession();
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timeString = '${WaktuHelper.getJamSekarang()} ${WaktuHelper.getZonaWaktu()}';
    _dateString = WaktuHelper.getTanggalLengkap();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeString = '${WaktuHelper.getJamSekarang()} ${WaktuHelper.getZonaWaktu()}';
          _dateString = WaktuHelper.getTanggalLengkap();
        });
      }
    });
  }

  Future<void> _syncUserSession() async {
    try {
      final response = await _authService.getUser();
      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          await Provider.of<UserProvider>(context, listen: false)
              .syncFromBackend(data);
        }
      } else {
        // Redirect ke login hanya jika 401 (token expired/invalid)
        final statusCode = response['statusCode'];
        if (statusCode == 401) {
          await _authService.clearLocalSession();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
        // Koneksi gagal (server mati) = biarkan tetap di dashboard dengan data lokal
      }
    } catch (e) {
      debugPrint('Error syncing user session: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await _notificationService.getNotifications(tipe: 'semua');
      if (!mounted) return;
      if (result['success'] == true && result['unread_counts'] != null) {
        final unreadCounts = result['unread_counts'] as Map<String, dynamic>;
        final count = unreadCounts['semua'];
        setState(() {
          _unreadCount = (count is int) ? count : int.tryParse(count.toString()) ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    final result = await _authService.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

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
    final userProvider = Provider.of<UserProvider>(context);
    final currentRole = userProvider.kedudukan;
    final displayName = userProvider.namaLengkap;

    // Define restricted tab pages based on roles
    Widget tab1 = const InventarisPage();
    if (!['ceo', 'manager', 'admin', 'warehouse'].contains(currentRole.toLowerCase())) {
      tab1 = AccessDeniedWidget(
        currentRole: currentRole,
        allowedRoles: const ['ceo', 'manager', 'admin', 'warehouse'],
        onBackToHome: () => setState(() => _currentIndex = 0),
      );
    }

    Widget tab2 = const PenjualanPage();
    if (!['ceo', 'manager', 'admin', 'cashier'].contains(currentRole.toLowerCase())) {
      tab2 = AccessDeniedWidget(
        currentRole: currentRole,
        allowedRoles: const ['ceo', 'manager', 'admin', 'cashier'],
        onBackToHome: () => setState(() => _currentIndex = 0),
      );
    }

    Widget tab3 = const PergerakanPage();
    if (!['ceo', 'manager', 'admin', 'warehouse'].contains(currentRole.toLowerCase())) {
      tab3 = AccessDeniedWidget(
        currentRole: currentRole,
        allowedRoles: const ['ceo', 'manager', 'admin', 'warehouse'],
        onBackToHome: () => setState(() => _currentIndex = 0),
      );
    }

    Widget tab4 = const LaporanPage();
    if (!['ceo', 'manager'].contains(currentRole.toLowerCase())) {
      tab4 = AccessDeniedWidget(
        currentRole: currentRole,
        allowedRoles: const ['ceo', 'manager'],
        onBackToHome: () => setState(() => _currentIndex = 0),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Warm off-white
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context, displayName, currentRole),
          tab1,
          tab2,
          tab3,
          tab4,
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventaris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Pergerakan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, String displayName, String role) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER (Gradient Coklat Keemasan)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color(0xFF5C3A21),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          ).then((_) => _syncUserSession());
                        },
                        child: Row(
                          children: [
                            // State-driven ProfilAvatar
                            const ProfilAvatar(size: 48),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  WaktuHelper.getGreeting(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getRoleLabel(role),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Notification & Refresh Icons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            onPressed: () {
                              _syncUserSession();
                              _loadUnreadCount();
                            },
                            tooltip: 'Refresh Data',
                          ),
                          IconButton(
                            icon: badges.Badge(
                              showBadge: _unreadCount > 0,
                              badgeContent: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
                              ).then((result) {
                                _loadUnreadCount();
                                if (result is Map && result.containsKey('tab')) {
                                  final targetTab = result['tab'] as int;
                                  setState(() {
                                    _currentIndex = targetTab;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Digital Clock Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dateString,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _timeString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. SUMMARY CARDS
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                    children: [
                      _buildSummaryCard(
                        title: 'Penjualan Hari Ini',
                        value: penjualanHariIni,
                        subtitle: '',
                        icon: Icons.monetization_on_outlined,
                        color: AppColors.primary,
                      ),
                      _buildSummaryCard(
                        title: 'Transaksi',
                        value: jumlahTransaksi.toString(),
                        subtitle: '',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.blue.shade700,
                      ),
                      _buildSummaryCard(
                        title: 'Total Produk',
                        value: totalProduk.toString(),
                        subtitle: '',
                        icon: Icons.grid_view_rounded,
                        color: Colors.teal.shade700,
                      ),
                      _buildSummaryCard(
                        title: 'Stok Menipis',
                        value: stokMenipis.toString(),
                        subtitle: '',
                        icon: Icons.gpp_maybe_outlined,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 3. CHART PENJUALAN MINGGUAN (EMPTY STATE)
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Penjualan Mingguan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                totalMingguan,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Grafik aktivitas penjualan produk',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Empty State Chart Area
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada data penjualan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Data akan muncul setelah transaksi pertama',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. LOW STOCK ALERT SECTION (EMPTY STATE)
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Peringatan Stok',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Daftar produk dengan jumlah stok di bawah batas minimal',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Empty State Low Stock
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Semua stok aman',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'LOGOUT JABATAN',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alert,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
