import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:badges/badges.dart' as badges;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'app_colors.dart';
import 'inventaris_page.dart';
import 'laporan_page.dart';

// --- DATA MODEL NOTIFIKASI ---
class NotifikasiModel {
  final String id;
  final String tipe; // stok|transaksi|laporan|sistem|promo
  final String judul;
  final String pesan;
  final DateTime waktu;
  bool sudahDibaca;
  final bool isUrgent;
  final Map<String, dynamic>? data;

  NotifikasiModel({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.waktu,
    required this.sudahDibaca,
    required this.isUrgent,
    this.data,
  });

  NotifikasiModel copyWith({
    String? id,
    String? tipe,
    String? judul,
    String? pesan,
    DateTime? waktu,
    bool? sudahDibaca,
    bool? isUrgent,
    Map<String, dynamic>? data,
  }) {
    return NotifikasiModel(
      id: id ?? this.id,
      tipe: tipe ?? this.tipe,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      waktu: waktu ?? this.waktu,
      sudahDibaca: sudahDibaca ?? this.sudahDibaca,
      isUrgent: isUrgent ?? this.isUrgent,
      data: data ?? this.data,
    );
  }
}

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Preference settings for notification
  bool _prefStock = true;
  bool _prefTx = true;
  bool _prefReport = true;
  bool _prefSystem = true;
  bool _prefPromo = false;
  double _stockThreshold = 10.0;
  String _reportFreq = 'weekly'; // daily|weekly|monthly

  // List of active notifications
  List<NotifikasiModel> _notifikasiList = [];
  
  // Backup list for 'Undo' action
  List<NotifikasiModel>? _notifikasiListBackup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Set Timeago locale to Indonesian
    timeago.setLocaleMessages('id', timeago.IdMessages());

    // Generate initial rich mock notifications
    _initializeMockData();

    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Redraw for dynamic tabs badge update
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    _notifikasiList = [
      NotifikasiModel(
        id: 'notif_1',
        tipe: 'stok',
        judul: '🚨 Stok Habis!',
        pesan: 'Produk Abon Ayam Pedas 150g telah HABIS. Segera hubungi bagian produksi.',
        waktu: now.subtract(const Duration(minutes: 10)),
        sudahDibaca: false,
        isUrgent: true,
        data: {'product_name': 'Abon Ayam Pedas 150g', 'stock': 0, 'min_stock': 5},
      ),
      NotifikasiModel(
        id: 'notif_2',
        tipe: 'transaksi',
        judul: '✅ Transaksi Berhasil!',
        pesan: 'Penjualan Abon Sapi Original 250g x5 senilai Rp 175.000 berhasil dicatat.',
        waktu: now.subtract(const Duration(minutes: 25)),
        sudahDibaca: false,
        isUrgent: false,
        data: {'tx_id': 'TX-98235', 'product_name': 'Abon Sapi Original 250g', 'qty': 5, 'total': 175000, 'method': 'Cash'},
      ),
      NotifikasiModel(
        id: 'notif_3',
        tipe: 'stok',
        judul: '⚠️ Stok Menipis!',
        pesan: 'Produk Abon Sapi Spesial 100g tersisa 3 pcs. Segera lakukan restock sebelum kehabisan.',
        waktu: now.subtract(const Duration(hours: 2)),
        sudahDibaca: false,
        isUrgent: true,
        data: {'product_name': 'Abon Sapi Spesial 100g', 'stock': 3, 'min_stock': 10},
      ),
      NotifikasiModel(
        id: 'notif_4',
        tipe: 'laporan',
        judul: '📊 Laporan Harian Siap',
        pesan: 'Laporan penjualan hari Minggu, 31 Mei 2026 sudah tersedia. Total pendapatan: Rp 1.250.000',
        waktu: now.subtract(const Duration(days: 1)),
        sudahDibaca: true,
        isUrgent: false,
        data: {'period': 'Minggu, 31 Mei 2026', 'total_revenue': 1250000, 'total_tx': 45},
      ),
      NotifikasiModel(
        id: 'notif_5',
        tipe: 'promo',
        judul: '🎯 Pengingat Stok Opname',
        pesan: 'Sudah 30 hari sejak stock opname terakhir. Yuk lakukan pengecekan stok sekarang!',
        waktu: now.subtract(const Duration(days: 3)),
        sudahDibaca: true,
        isUrgent: false,
        data: {'last_check': '30 hari lalu'},
      ),
      NotifikasiModel(
        id: 'notif_6',
        tipe: 'laporan',
        judul: '📈 Laporan Mingguan Siap',
        pesan: 'Laporan penjualan periode 24 Mei - 30 Mei 2026 sudah tersedia. Klik untuk melihat performa tokomu.',
        waktu: now.subtract(const Duration(days: 2)),
        sudahDibaca: false,
        isUrgent: false,
        data: {'period': '24 Mei - 30 Mei 2026', 'total_revenue': 8450000, 'total_tx': 280},
      ),
      NotifikasiModel(
        id: 'notif_7',
        tipe: 'sistem',
        judul: 'ℹ️ Selamat Datang!',
        pesan: 'Akun Anda berhasil dibuat. Mulai kelola usaha abon Anda dengan lebih mudah bersama Abon Salakopi App.',
        waktu: now.subtract(const Duration(days: 5)),
        sudahDibaca: true,
        isUrgent: false,
        data: {'welcome': true},
      ),
    ];
  }

  // Helper getters
  int get _unreadCount => _notifikasiList.where((n) => !n.sudahDibaca).length;

  int _countForTab(String tabType) {
    if (tabType == 'semua') return _notifikasiList.length;
    if (tabType == 'sistem') {
      // System tab matches both 'sistem' and 'promo' types
      return _notifikasiList.where((n) => n.tipe == 'sistem' || n.tipe == 'promo').length;
    }
    return _notifikasiList.where((n) => n.tipe == tabType).length;
  }

  int _unreadCountForTab(String tabType) {
    if (tabType == 'semua') return _unreadCount;
    if (tabType == 'sistem') {
      return _notifikasiList.where((n) => !n.sudahDibaca && (n.tipe == 'sistem' || n.tipe == 'promo')).length;
    }
    return _notifikasiList.where((n) => !n.sudahDibaca && n.tipe == tabType).length;
  }

  List<NotifikasiModel> _filterList(String tabType) {
    List<NotifikasiModel> filtered;
    if (tabType == 'semua') {
      filtered = List.from(_notifikasiList);
    } else if (tabType == 'sistem') {
      filtered = _notifikasiList.where((n) => n.tipe == 'sistem' || n.tipe == 'promo').toList();
    } else {
      filtered = _notifikasiList.where((n) => n.tipe == tabType).toList();
    }
    
    // Sort descending by time
    filtered.sort((a, b) => b.waktu.compareTo(a.waktu));
    return filtered;
  }

  // --- ACTIONS ---
  void _toggleRead(String id) {
    setState(() {
      final index = _notifikasiList.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifikasiList[index].sudahDibaca = !_notifikasiList[index].sudahDibaca;
      }
    });
  }

  void _markAllAsRead() {
    final hasUnread = _notifikasiList.any((n) => !n.sudahDibaca);
    if (!hasUnread) return;

    // Backup state for Undo
    _notifikasiListBackup = _notifikasiList.map((n) => n.copyWith()).toList();

    setState(() {
      for (var n in _notifikasiList) {
        n.sudahDibaca = true;
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF8B5E3C), // primaryBrownDark
        content: const Row(
          children: [
            Icon(Icons.done_all_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('✓ Semua notifikasi ditandai dibaca'),
          ],
        ),
        action: SnackBarAction(
          label: 'URUNGKAN',
          textColor: Colors.white,
          onPressed: () {
            if (_notifikasiListBackup != null) {
              setState(() {
                _notifikasiList = List.from(_notifikasiListBackup!);
              });
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _deleteNotif(String id) {
    setState(() {
      _notifikasiList.removeWhere((n) => n.id == id);
    });
  }

  void _deleteAllConfirm() {
    showDialog(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        onConfirm: () {
          setState(() {
            // Keep urgent ones, delete others
            _notifikasiList.removeWhere((n) => !n.isUrgent);
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.alert,
              content: Text('Notifikasi non-urgent berhasil dihapus.'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pullToRefresh() async {
    // Custom pull-to-refresh shaking animation simulator
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _initializeMockData();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          content: Text('Notifikasi telah diperbarui!'),
        ),
      );
    }
  }

  void _showDetailSheet(NotifikasiModel notif) {
    // Automatically mark as read when tapped
    if (!notif.sudahDibaca) {
      _toggleRead(notif.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetailSheet(
        notif: notif,
        onDelete: () {
          _deleteNotif(notif.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _NotificationSettingPage(
          prefStock: _prefStock,
          prefTx: _prefTx,
          prefReport: _prefReport,
          prefSystem: _prefSystem,
          prefPromo: _prefPromo,
          stockThreshold: _stockThreshold,
          reportFreq: _reportFreq,
          onSave: (stock, tx, report, sys, promo, threshold, freq) {
            setState(() {
              _prefStock = stock;
              _prefTx = tx;
              _prefReport = report;
              _prefSystem = sys;
              _prefPromo = promo;
              _stockThreshold = threshold;
              _reportFreq = freq;
            });
          },
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, NotifikasiModel notif) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: Icon(
                  notif.sudahDibaca ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  notif.sudahDibaca ? 'Tandai Belum Dibaca' : 'Tandai Sudah Dibaca',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleRead(notif.id);
                },
              ),
              if (!notif.isUrgent)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.alert),
                  title: const Text(
                    'Hapus Notifikasi',
                    style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteNotif(notif.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Batal', style: TextStyle(color: Colors.grey)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = _getCurrentTabType();
    final items = _filterList(activeTab);

    // Grouping items by date group
    final groupedItems = _groupNotifications(items);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. HEADER SECTION
          _HeaderSection(
            unreadCount: _unreadCount,
            onMarkAllRead: _markAllAsRead,
            onOpenSettings: _openSettings,
          ),

          // 2. FILTER TAB BAR (Sticky-like under header)
          _FilterTabBar(
            tabController: _tabController,
            unreadStock: _unreadCountForTab('stok'),
            unreadTx: _unreadCountForTab('transaksi'),
            unreadReport: _unreadCountForTab('laporan'),
            unreadSys: _unreadCountForTab('sistem'),
            unreadAll: _unreadCountForTab('semua'),
          ),

          // 3. SUMMARY BANNER (if there are important unread notifications)
          _SummaryBanner(
            notifications: _notifikasiList,
            onViewAlerts: () {
              // Direct switch to Stock tab (Index 1)
              _tabController.animateTo(1);
            },
          ),

          // 4. ACTION BAR
          _ActionBar(
            unreadCount: _unreadCountForTab(activeTab),
            onMarkAllRead: _markAllAsRead,
            onDeleteAll: _deleteAllConfirm,
          ),

          // 5. NOTIFICATION LIST WITH SWIPE & PULL TO REFRESH
          Expanded(
            child: RefreshIndicator(
              onRefresh: _pullToRefresh,
              color: AppColors.accent,
              backgroundColor: Colors.white,
              child: items.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.only(top: 80.0),
                        child: _EmptyState(
                          tabType: activeTab,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: groupedItems.keys.length,
                      itemBuilder: (context, groupIdx) {
                        final groupTitle = groupedItems.keys.elementAt(groupIdx);
                        final groupList = groupedItems[groupTitle]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time Group Header
                            _NotificationGroupHeader(title: groupTitle),
                            
                            // Notifications within group
                            ...groupList.map((notif) {
                              return _NotificationCard(
                                notif: notif,
                                onTap: () => _showDetailSheet(notif),
                                onSwipeRead: () => _toggleRead(notif.id),
                                onSwipeDelete: notif.isUrgent ? null : () => _deleteNotif(notif.id),
                                onLongPress: () => _showContextMenu(context, notif),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTabType() {
    switch (_tabController.index) {
      case 0:
        return 'semua';
      case 1:
        return 'stok';
      case 2:
        return 'transaksi';
      case 3:
        return 'laporan';
      case 4:
        return 'sistem';
      default:
        return 'semua';
    }
  }

  Map<String, List<NotifikasiModel>> _groupNotifications(List<NotifikasiModel> list) {
    final Map<String, List<NotifikasiModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    for (var notif in list) {
      final notifDate = DateTime(notif.waktu.year, notif.waktu.month, notif.waktu.day);
      String groupTitle;

      if (notifDate == today) {
        groupTitle = 'Hari Ini';
      } else if (notifDate == yesterday) {
        groupTitle = 'Kemarin';
      } else if (notifDate.isAfter(weekAgo)) {
        groupTitle = 'Minggu Ini';
      } else {
        groupTitle = 'Lebih Lama';
      }

      if (!groups.containsKey(groupTitle)) {
        groups[groupTitle] = [];
      }
      groups[groupTitle]!.add(notif);
    }

    return groups;
  }
}

// ═══════════════════════════════════════
// WIDGET COMPONENTS IMPLEMENTATIONS
// ═══════════════════════════════════════

// --- 1. HEADER SECTION ---
class _HeaderSection extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onOpenSettings;

  const _HeaderSection({
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, statusBarHeight + 12.0, 16.0, 20.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5E3C), // Primary Brown
            Color(0xFFB37B50), // Lighter Golden Brown
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),

              // Title Centered with Badge
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($unreadCount belum dibaca)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              // Action Icons: Check & Settings
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
                    tooltip: 'Tandai Semua Dibaca',
                    onPressed: onMarkAllRead,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                    tooltip: 'Pengaturan Notifikasi',
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. FILTER TAB BAR ---
class _FilterTabBar extends StatelessWidget {
  final TabController tabController;
  final int unreadAll;
  final int unreadStock;
  final int unreadTx;
  final int unreadReport;
  final int unreadSys;

  const _FilterTabBar({
    required this.tabController,
    required this.unreadAll,
    required this.unreadStock,
    required this.unreadTx,
    required this.unreadReport,
    required this.unreadSys,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildTabItem(0, 'Semua', null, unreadAll),
            _buildTabItem(1, 'Stok', AppColors.alert, unreadStock),
            _buildTabItem(2, 'Transaksi', AppColors.success, unreadTx),
            _buildTabItem(3, 'Laporan', const Color(0xFF2196F3), unreadReport),
            _buildTabItem(4, 'Sistem', const Color(0xFF9E9E9E), unreadSys),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, Color? iconColor, int unreadBadge) {
    final isActive = tabController.index == index;

    return GestureDetector(
      onTap: () => tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (unreadBadge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.alert,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadBadge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- 3. SUMMARY BANNER ---
class _SummaryBanner extends StatelessWidget {
  final List<NotifikasiModel> notifications;
  final VoidCallback onViewAlerts;

  const _SummaryBanner({
    required this.notifications,
    required this.onViewAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final unreadImportant = notifications.where((n) => !n.sudahDibaca && (n.isUrgent || n.tipe == 'stok')).toList();
    final unreadReports = notifications.where((n) => !n.sudahDibaca && n.tipe == 'laporan').toList();

    if (unreadImportant.isEmpty && unreadReports.isEmpty) {
      return const SizedBox.shrink();
    }

    String headingText = '';
    String subText = '';

    if (unreadImportant.isNotEmpty) {
      headingText = '🔴 ${unreadImportant.length} notifikasi perlu perhatian';
      subText = '${unreadImportant.length} stok menipis/habis';
      if (unreadReports.isNotEmpty) {
        subText += ' · ${unreadReports.length} laporan baru';
      }
    } else {
      headingText = '📊 Laporan Baru Tersedia';
      subText = '${unreadReports.length} laporan siap dianalisis';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F2), // Krem background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headingText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF8B5E3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onViewAlerts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. ACTION BAR ---
class _ActionBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;

  const _ActionBar({
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$unreadCount notifikasi belum dibaca',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onMarkAllRead,
                child: const Text(
                  'Baca Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('|', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              GestureDetector(
                onTap: onDeleteAll,
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.alert,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Group Header ---
class _NotificationGroupHeader extends StatelessWidget {
  final String title;

  const _NotificationGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor = Colors.grey;
    if (title == 'Hari Ini') indicatorColor = AppColors.alert;
    if (title == 'Kemarin') indicatorColor = AppColors.warning;

    return Container(
      width: double.infinity,
      color: const Color(0xFFFDFBF9),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 5. NOTIFICATION CARD WIDGET ---
class _NotificationCard extends StatefulWidget {
  final NotifikasiModel notif;
  final VoidCallback onTap;
  final VoidCallback onSwipeRead;
  final VoidCallback? onSwipeDelete;
  final VoidCallback onLongPress;

  const _NotificationCard({
    required this.notif,
    required this.onTap,
    required this.onSwipeRead,
    required this.onSwipeDelete,
    required this.onLongPress,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;

    // Determine color codes
    Color borderLeftColor = Colors.grey;
    IconData cardIcon = Icons.info_rounded;
    Color iconCircleColor = Colors.grey[100]!;
    Color iconColor = Colors.grey;
    String badgeText = 'INFO';

    switch (notif.tipe) {
      case 'stok':
        borderLeftColor = AppColors.alert;
        cardIcon = notif.isUrgent ? Icons.warning_rounded : Icons.warning_amber_rounded;
        iconCircleColor = const Color(0xFFFFEBEE);
        iconColor = AppColors.alert;
        badgeText = notif.isUrgent ? 'HABIS' : 'STOK';
        break;
      case 'transaksi':
        borderLeftColor = AppColors.success;
        cardIcon = Icons.shopping_bag_rounded;
        iconCircleColor = const Color(0xFFE8F5E9);
        iconColor = AppColors.success;
        badgeText = 'TRANSAKSI';
        break;
      case 'laporan':
        borderLeftColor = const Color(0xFF2196F3);
        cardIcon = Icons.analytics_rounded;
        iconCircleColor = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF2196F3);
        badgeText = 'LAPORAN';
        break;
      case 'sistem':
        borderLeftColor = const Color(0xFF9E9E9E);
        cardIcon = Icons.info_rounded;
        iconCircleColor = const Color(0xFFF5F5F5);
        iconColor = const Color(0xFF757575);
        badgeText = 'SISTEM';
        break;
      case 'promo':
        borderLeftColor = AppColors.accent;
        cardIcon = Icons.campaign_rounded;
        iconCircleColor = const Color(0xFFFFF8E1);
        iconColor = AppColors.primary;
        badgeText = 'INFO';
        break;
    }

    final cardBgColor = notif.sudahDibaca ? Colors.white : const Color(0xFFFFF9F5);
    final borderThickness = notif.isUrgent ? 4.5 : 3.0;

    return Slidable(
      key: ValueKey(notif.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => widget.onSwipeRead(),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon: notif.sudahDibaca ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
            label: notif.sudahDibaca ? 'Belum Baca' : 'Baca',
          ),
        ],
      ),
      endActionPane: widget.onSwipeDelete == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) => widget.onSwipeDelete!(),
                  backgroundColor: AppColors.alert,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                ),
              ],
            ),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(notif.sudahDibaca ? 0.02 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: notif.sudahDibaca ? Colors.grey[200]! : AppColors.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Color Border Left
                  Container(
                    width: borderThickness,
                    color: borderLeftColor,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar: Dot, Type Badge, Title, Time
                          Row(
                            children: [
                              // Unread indicator dot
                              if (!notif.sudahDibaca) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2196F3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],

                              // Type Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconCircleColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              // URGENT Pulsing Badge
                              if (notif.isUrgent) ...[
                                const SizedBox(width: 6),
                                FadeTransition(
                                  opacity: _pulseController,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.alert,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // Relative time
                              Text(
                                timeago.format(notif.waktu, locale: 'id'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Message Body: Icon + Texts
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Circular Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconCircleColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cardIcon,
                                  color: iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Header & Message Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.judul,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.sudahDibaca ? FontWeight.bold : FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.pesan,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: notif.sudahDibaca ? Colors.grey[600] : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    // Custom actions inside card
                                    _buildCardAction(notif),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildCardAction(NotifikasiModel notif) {
    if (notif.tipe == 'stok') {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: OutlinedButton(
          onPressed: () {
            // Direct navigate to InventarisPage
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const InventarisPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.alert, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Restock Sekarang',
            style: TextStyle(color: AppColors.alert, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (notif.tipe == 'laporan') {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: OutlinedButton(
          onPressed: () {
            // Direct navigate to LaporanPage
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LaporanPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Lihat Laporan',
            style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (notif.tipe == 'promo') {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: OutlinedButton(
          onPressed: () {
            // Simulated check action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Membuka stock opname wizard...')),
            );
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cek Sekarang',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// --- 6. NOTIFICATION DETAIL SHEET ---
class _NotificationDetailSheet extends StatelessWidget {
  final NotifikasiModel notif;
  final VoidCallback onDelete;

  const _NotificationDetailSheet({
    required this.notif,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = Colors.grey;
    IconData sheetIcon = Icons.info_rounded;
    Color circleColor = Colors.grey[100]!;
    String typeLabel = 'INFO SISTEM';

    switch (notif.tipe) {
      case 'stok':
        typeColor = AppColors.alert;
        sheetIcon = Icons.warning_rounded;
        circleColor = const Color(0xFFFFEBEE);
        typeLabel = notif.isUrgent ? 'KRITIS - RESTOCK DIBUTUHKAN' : 'PERINGATAN STOK';
        break;
      case 'transaksi':
        typeColor = AppColors.success;
        sheetIcon = Icons.shopping_bag_rounded;
        circleColor = const Color(0xFFE8F5E9);
        typeLabel = 'TRANSAKSI BERHASIL';
        break;
      case 'laporan':
        typeColor = const Color(0xFF2196F3);
        sheetIcon = Icons.analytics_rounded;
        circleColor = const Color(0xFFE3F2FD);
        typeLabel = 'LAPORAN BARU SIAP';
        break;
      case 'promo':
        typeColor = AppColors.accent;
        sheetIcon = Icons.campaign_rounded;
        circleColor = const Color(0xFFFFF8E1);
        typeLabel = 'PENGINGAT SISTEM';
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center small drag bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Top Icon (Large 56px inside circle)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sheetIcon,
                  color: typeColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Badge Type
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: circleColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification Title
            Text(
              notif.judul,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Complete Date Time display
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id_ID').format(notif.waktu),
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detailed notification message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Text(
                notif.pesan,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 16),

            // Info tambahan sesuai tipe
            _buildAdditionalMeta(context),
            const SizedBox(height: 24),

            // Action Buttons
            _buildDetailActionBtn(context),
            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),

            if (!notif.isUrgent) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onDelete,
                child: const Center(
                  child: Text(
                    'Hapus Notifikasi',
                    style: TextStyle(
                      color: AppColors.alert,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalMeta(BuildContext context) {
    final data = notif.data;
    if (data == null) return const SizedBox.shrink();

    if (notif.tipe == 'stok') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.alert.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _buildMetaRow('Nama Produk:', data['product_name'] ?? '-'),
            const SizedBox(height: 6),
            _buildMetaRow('Stok Saat Ini:', '${data['stock'] ?? 0} pcs', valColor: AppColors.alert),
            const SizedBox(height: 6),
            _buildMetaRow('Batas Min Stok:', '${data['min_stock'] ?? 0} pcs'),
          ],
        ),
      );
    } else if (notif.tipe == 'transaksi') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _buildMetaRow('ID Transaksi:', data['tx_id'] ?? '-'),
            const SizedBox(height: 6),
            _buildMetaRow('Nama Produk:', data['product_name'] ?? '-'),
            const SizedBox(height: 6),
            _buildMetaRow('Jumlah (Qty):', 'x${data['qty'] ?? 0}'),
            const SizedBox(height: 6),
            _buildMetaRow('Metode Pembayaran:', data['method'] ?? '-'),
            const Divider(height: 16),
            _buildMetaRow(
              'Total Pendapatan:',
              'Rp ${NumberFormat.decimalPattern('id_ID').format(data['total'] ?? 0)}',
              valColor: AppColors.success,
              isBold: true,
            ),
          ],
        ),
      );
    } else if (notif.tipe == 'laporan') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _buildMetaRow('Periode Laporan:', data['period'] ?? '-'),
            const SizedBox(height: 6),
            _buildMetaRow('Jumlah Transaksi:', '${data['total_tx'] ?? 0} transaksi'),
            const Divider(height: 16),
            _buildMetaRow(
              'Total Pendapatan:',
              'Rp ${NumberFormat.decimalPattern('id_ID').format(data['total_revenue'] ?? 0)}',
              valColor: Colors.blue,
              isBold: true,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMetaRow(String label, String value, {Color? valColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActionBtn(BuildContext context) {
    if (notif.tipe == 'stok') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const InventarisPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.alert,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Restock Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (notif.tipe == 'laporan') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LaporanPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.bar_chart_outlined),
        label: const Text('Lihat Laporan Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (notif.tipe == 'transaksi') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menampilkan detail struk penjualan...')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Lihat Detail Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }
}

// --- 7. EMPTY STATE WIDGET ---
class _EmptyState extends StatelessWidget {
  final String tabType;
  final VoidCallback onBack;

  const _EmptyState({
    required this.tabType,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    IconData emptyIcon = Icons.notifications_none_rounded;
    String emptyTitle = 'Tidak Ada Notifikasi';
    String emptyDesc = 'Semua notifikasi akan muncul di sini secara otomatis';

    switch (tabType) {
      case 'stok':
        emptyIcon = Icons.inventory_outlined;
        emptyTitle = 'Tidak Ada Peringatan Stok';
        emptyDesc = 'Semua stok produk Anda terpantau aman dan cukup.';
        break;
      case 'transaksi':
        emptyIcon = Icons.receipt_outlined;
        emptyTitle = 'Belum Ada Transaksi';
        emptyDesc = 'Notifikasi konfirmasi penjualan masuk akan tampil di sini.';
        break;
      case 'laporan':
        emptyIcon = Icons.analytics_outlined;
        emptyTitle = 'Belum Ada Laporan';
        emptyDesc = 'Laporan harian, mingguan, atau bulanan belum tersedia saat ini.';
        break;
      case 'sistem':
        emptyIcon = Icons.info_outlined;
        emptyTitle = 'Tidak Ada Info Sistem';
        emptyDesc = 'Update aplikasi terbaru dan tip fitur akan diumumkan di sini.';
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // shaking/rotating bell simulation in center
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              emptyIcon,
              color: AppColors.primary.withOpacity(0.4),
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          emptyTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            emptyDesc,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),

        Center(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Kembali ke Dashboard',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 8. DELETE CONFIRM DIALOG ---
class _DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Hapus Semua Notifikasi?',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
      ),
      content: const Text(
        'Tindakan ini akan menghapus semua notifikasi kecuali yang berstatus penting (URGENT). Tindakan ini tidak dapat dibatalkan.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.alert,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// --- 9. NOTIFICATION SETTING PAGE ---
class _NotificationSettingPage extends StatefulWidget {
  final bool prefStock;
  final bool prefTx;
  final bool prefReport;
  final bool prefSystem;
  final bool prefPromo;
  final double stockThreshold;
  final String reportFreq;
  final Function(bool, bool, bool, bool, bool, double, String) onSave;

  const _NotificationSettingPage({
    required this.prefStock,
    required this.prefTx,
    required this.prefReport,
    required this.prefSystem,
    required this.prefPromo,
    required this.stockThreshold,
    required this.reportFreq,
    required this.onSave,
  });

  @override
  State<_NotificationSettingPage> createState() => _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<_NotificationSettingPage> {
  late bool _prefStock;
  late bool _prefTx;
  late bool _prefReport;
  late bool _prefSystem;
  late bool _prefPromo;
  late double _stockThreshold;
  late String _reportFreq;

  @override
  void initState() {
    super.initState();
    _prefStock = widget.prefStock;
    _prefTx = widget.prefTx;
    _prefReport = widget.prefReport;
    _prefSystem = widget.prefSystem;
    _prefPromo = widget.prefPromo;
    _stockThreshold = widget.stockThreshold;
    _reportFreq = widget.reportFreq;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PREFERENSI NOTIFIKASI',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildToggleTile(
                    'Peringatan Stok',
                    'Notifikasi saat stok produk menipis atau habis',
                    _prefStock,
                    AppColors.alert,
                    (val) => setState(() => _prefStock = val),
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    'Konfirmasi Transaksi',
                    'Notifikasi untuk setiap transaksi baru yang dicatat',
                    _prefTx,
                    AppColors.success,
                    (val) => setState(() => _prefTx = val),
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    'Laporan Siap',
                    'Notifikasi saat laporan penjualan harian/mingguan siap',
                    _prefReport,
                    Colors.blue,
                    (val) => setState(() => _prefReport = val),
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    'Info Sistem',
                    'Notifikasi update aplikasi dan pemberitahuan penting',
                    _prefSystem,
                    Colors.grey,
                    (val) => setState(() => _prefSystem = val),
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    'Pengingat & Promo',
                    'Notifikasi event, promo, dan tips optimasi produk',
                    _prefPromo,
                    AppColors.accent,
                    (val) => setState(() => _prefPromo = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'BATAS STOK MENIPIS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peringatan pada stok ≤',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_stockThreshold.round()} pcs',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _stockThreshold,
                    min: 2,
                    max: 50,
                    divisions: 48,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.secondary,
                    onChanged: (val) {
                      setState(() {
                        _stockThreshold = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'FREKUENSI LAPORAN',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildRadioTile('Harian (setiap jam 20:00)', 'daily'),
                  const Divider(height: 1),
                  _buildRadioTile('Mingguan (setiap Senin)', 'weekly'),
                  const Divider(height: 1),
                  _buildRadioTile('Bulanan (setiap tanggal 1)', 'monthly'),
                ],
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _prefStock,
                  _prefTx,
                  _prefReport,
                  _prefSystem,
                  _prefPromo,
                  _stockThreshold,
                  _reportFreq,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                    content: Text('✓ Preferensi notifikasi berhasil disimpan!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Simpan Pengaturan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, Color indicatorColor, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      secondary: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildRadioTile(String title, String val) {
    return RadioListTile<String>(
      value: val,
      groupValue: _reportFreq,
      activeColor: AppColors.primary,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _reportFreq = value;
          });
        }
      },
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }
}
