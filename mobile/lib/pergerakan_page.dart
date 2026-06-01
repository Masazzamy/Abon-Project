import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'app_colors.dart';

class PergerakanPage extends StatefulWidget {
  const PergerakanPage({super.key});

  @override
  State<PergerakanPage> createState() => _PergerakanPageState();
}

class _PergerakanPageState extends State<PergerakanPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _flowController;

  // Active state lists
  final List<Map<String, dynamic>> _pergerakanList = [];
  
  // Mock Inventory products for dropdown selection
  final List<Map<String, dynamic>> _mockInventory = [
    {'id': '1', 'nama': 'Abon Sapi Original 250g', 'stok': 25},
    {'id': '2', 'nama': 'Abon Sapi Pedas 250g', 'stok': 18},
    {'id': '3', 'nama': 'Abon Ayam Original 150g', 'stok': 30},
    {'id': '4', 'nama': 'Abon Ayam Pedas 150g', 'stok': 15},
    {'id': '5', 'nama': 'Camilan Salakopi Crispy', 'stok': 40},
  ];

  // Filters and states
  String _searchQuery = "";
  String _sortOption = "Terbaru"; // Terbaru, Terlama, Terbanyak, Tersedikit
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Repeating controller for flow diagram animation
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Populate initial default mock pergerakan data
    final today = DateTime.now();
    _pergerakanList.addAll([
      {
        'id': 'MVT-004',
        'type': 'RETUR',
        'nama': 'Camilan Salakopi Crispy',
        'qty': 3,
        'sisa': 43,
        'sisaSebelum': 40,
        'dateTime': today.subtract(const Duration(minutes: 45)),
        'user': 'Masazzamy',
        'notes': 'Produk dikembalikan pembeli karena salah varian',
      },
      {
        'id': 'MVT-003',
        'type': 'KOREKSI',
        'nama': 'Abon Ayam Original 150g',
        'qty': -2,
        'sisa': 28,
        'sisaSebelum': 30,
        'dateTime': today.subtract(const Duration(hours: 2)),
        'user': 'Masazzamy',
        'notes': 'Stock opname - kemasan bocor 2 pcs',
      },
      {
        'id': 'MVT-002',
        'type': 'KELUAR',
        'nama': 'Abon Sapi Pedas 250g',
        'qty': -5,
        'sisa': 13,
        'sisaSebelum': 18,
        'dateTime': today.subtract(const Duration(hours: 3)),
        'user': 'Masazzamy',
        'notes': 'Penjualan TRX-1002',
      },
      {
        'id': 'MVT-001',
        'type': 'MASUK',
        'nama': 'Abon Sapi Original 250g',
        'qty': 10,
        'sisa': 35,
        'sisaSebelum': 25,
        'dateTime': today.subtract(const Duration(hours: 5)),
        'user': 'Masazzamy',
        'notes': 'Hasil produksi batch #012',
      },
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flowController.dispose();
    super.dispose();
  }

  void _triggerLoading() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Summary figures for today
  int get _todayMasukCount {
    final today = DateTime.now();
    return _pergerakanList.where((p) {
      final date = p['dateTime'] as DateTime;
      return p['type'] == 'MASUK' && date.day == today.day && date.month == today.month && date.year == today.year;
    }).fold(0, (sum, p) => sum + (p['qty'] as int));
  }

  int get _todayKeluarCount {
    final today = DateTime.now();
    return _pergerakanList.where((p) {
      final date = p['dateTime'] as DateTime;
      return p['type'] == 'KELUAR' && date.day == today.day && date.month == today.month && date.year == today.year;
    }).fold(0, (sum, p) => sum + (p['qty'] as int).abs());
  }

  int get _todayKoreksiCount {
    final today = DateTime.now();
    return _pergerakanList.where((p) {
      final date = p['dateTime'] as DateTime;
      return p['type'] == 'KOREKSI' && date.day == today.day && date.month == today.month && date.year == today.year;
    }).fold(0, (sum, p) => sum + (p['qty'] as int).abs());
  }

  int get _todayReturCount {
    final today = DateTime.now();
    return _pergerakanList.where((p) {
      final date = p['dateTime'] as DateTime;
      return p['type'] == 'RETUR' && date.day == today.day && date.month == today.month && date.year == today.year;
    }).fold(0, (sum, p) => sum + (p['qty'] as int));
  }

  int get _totalStokGudang {
    return _mockInventory.fold(0, (sum, p) => sum + (p['stok'] as int));
  }

  // Stock health status
  String get _stockHealthStatus {
    final lowStockCount = _mockInventory.where((p) => (p['stok'] as int) > 0 && (p['stok'] as int) <= 10).length;
    final outOfStockCount = _mockInventory.where((p) => (p['stok'] as int) == 0).length;

    if (outOfStockCount > 0) {
      return "✗ $outOfStockCount produk stok habis!";
    } else if (lowStockCount > 0) {
      return "⚠ $lowStockCount produk perlu diperhatikan (stok menipis)";
    } else {
      return "✓ Semua stok dalam kondisi baik";
    }
  }

  Color get _stockHealthColor {
    final status = _stockHealthStatus;
    if (status.startsWith("✓")) {
      return AppColors.success;
    } else if (status.startsWith("⚠")) {
      return AppColors.warning;
    } else {
      return AppColors.alert;
    }
  }

  // Tab dynamic counts
  int _tabCount(String tabType) {
    if (tabType == "Semua") return _pergerakanList.length;
    return _pergerakanList.where((p) => p['type'] == tabType).length;
  }

  // Date Group and Filter logics
  List<Map<String, dynamic>> _getFilteredList(String tabType) {
    List<Map<String, dynamic>> result = _pergerakanList;
    
    // Tab filter
    if (tabType != "Semua") {
      result = result.where((p) => p['type'] == tabType).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        final query = _searchQuery.toLowerCase();
        return p['nama'].toString().toLowerCase().contains(query) ||
            p['notes'].toString().toLowerCase().contains(query) ||
            p['id'].toString().toLowerCase().contains(query);
      }).toList();
    }

    // Date range filter
    if (_selectedDateRange != null) {
      result = result.where((p) {
        final date = p['dateTime'] as DateTime;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sorting logic
    if (_sortOption == "Terbaru") {
      result.sort((a, b) => (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime));
    } else if (_sortOption == "Terlama") {
      result.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));
    } else if (_sortOption == "Terbanyak") {
      result.sort((a, b) => (b['qty'] as int).abs().compareTo((a['qty'] as int).abs()));
    } else if (_sortOption == "Tersedikit") {
      result.sort((a, b) => (a['qty'] as int).abs().compareTo((b['qty'] as int).abs()));
    }

    return result;
  }

  // Group movements by date string
  Map<String, List<Map<String, dynamic>>> _getGroupedList(String tabType) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final filtered = _getFilteredList(tabType);

    for (var mvt in filtered) {
      final date = mvt['dateTime'] as DateTime;
      final dateStr = _formatDateIndo(date);
      if (groups.containsKey(dateStr)) {
        groups[dateStr]!.add(mvt);
      } else {
        groups[dateStr] = [mvt];
      }
    }
    return groups;
  }

  String _formatDateIndo(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dayStr = days[date.weekday % 7];
    final monthStr = months[date.month - 1];
    return '$dayStr, ${date.day} $monthStr ${date.year}';
  }

  // Add movement record
  void _addMovement(Map<String, dynamic> data) {
    final product = _mockInventory.firstWhere((p) => p['id'] == data['productId']);
    final int currentStock = product['stok'] as int;
    final int changeQty = data['qty'] as int;
    final int newStock = currentStock + changeQty;

    // Update main inventory stock
    setState(() {
      product['stok'] = newStock;
      
      final today = DateTime.now();
      _pergerakanList.insert(0, {
        'id': 'MVT-${1000 + _pergerakanList.length + 1}',
        'type': data['type'],
        'nama': product['nama'],
        'qty': changeQty,
        'sisa': newStock,
        'sisaSebelum': currentStock,
        'dateTime': data['dateTime'] ?? today,
        'user': 'Masazzamy',
        'notes': data['notes'],
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pergerakan ${data['type']} berhasil dicatat!"),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Delete movement (with Stock rollback)
  void _deleteMovement(Map<String, dynamic> mvt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Tindakan ini akan mengembalikan jumlah stok ke semula dan menghapus permanen riwayat pergerakan ini."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rollbackMovement(mvt);
            },
            child: const Text("Hapus & Rollback", style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _rollbackMovement(Map<String, dynamic> mvt) {
    final product = _mockInventory.firstWhere((p) => p['nama'] == mvt['nama'], orElse: () => {});
    if (product.isNotEmpty) {
      setState(() {
        // Rollback current stock (invert the quantity adjustment)
        product['stok'] = (product['stok'] as int) - (mvt['qty'] as int);
        _pergerakanList.removeWhere((item) => item['id'] == mvt['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Catatan ${mvt['id']} dihapus, stok dikembalikan."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Open Sheets
  void _openCatatPergerakan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewMovementSheet(
        inventory: _mockInventory,
        onConfirm: _addMovement,
      ),
    );
  }

  void _openMovementDetail(Map<String, dynamic> mvt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MovementDetailSheet(
        movement: mvt,
        onDelete: () {
          Navigator.pop(context);
          _deleteMovement(mvt);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. Header Section
              _HeaderSection(onAddPressed: _openCatatPergerakan),

              // Sticky widgets above tabs (Summary, visualization, stock timeline)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    
                    // 2. Summary Strip
                    _SummaryStrip(
                      masuk: _todayMasukCount,
                      keluar: _todayKeluarCount,
                      koreksi: _todayKoreksiCount,
                      retur: _todayReturCount,
                    ),

                    // 3. Stock Health Indicator
                    _StockHealthIndicator(
                      message: _stockHealthStatus,
                      color: _stockHealthColor,
                    ),
                    const SizedBox(height: 16),

                    // 4. Flow Visualization
                    _FlowVisualization(
                      masuk: _todayMasukCount,
                      gudang: _totalStokGudang,
                      keluar: _todayKeluarCount,
                      animationController: _flowController,
                    ),
                    const SizedBox(height: 20),

                    // Quick Action Buttons & Timeline Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _openCatatPergerakan();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success.withOpacity(0.1),
                                foregroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                minimumSize: const Size(0, 42),
                              ),
                              icon: const Icon(Icons.arrow_circle_down_rounded, size: 18),
                              label: const Text("Terima Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _openCatatPergerakan();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                minimumSize: const Size(0, 42),
                              ),
                              icon: const Icon(Icons.inventory_2_rounded, size: 18),
                              label: const Text("Stock Opname", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mini 7 Day Stock Timeline
                    _StockTimeline(movements: _pergerakanList),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // 5. Tab Bar header (Sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.grey.withOpacity(0.15),
                    tabs: [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Semua"), const SizedBox(width: 4), _buildBadgeTab(_tabCount("Semua"))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.arrow_circle_down_rounded, size: 16, color: AppColors.success), const SizedBox(width: 4), _buildBadgeTab(_tabCount("MASUK"))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.arrow_circle_up_rounded, size: 16, color: AppColors.alert), const SizedBox(width: 4), _buildBadgeTab(_tabCount("KELUAR"))])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.warning), const SizedBox(width: 4), _buildBadgeTab(_tabCount("KOREKSI"))])),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMovementTab("Semua"),
              _buildMovementTab("MASUK"),
              _buildMovementTab("KELUAR"),
              _buildMovementTab("KOREKSI"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeTab(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Text("$count", style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMovementTab(String type) {
    final grouped = _getGroupedList(type);

    return RefreshIndicator(
      onRefresh: () async {
        _triggerLoading();
        await Future.delayed(const Duration(milliseconds: 400));
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Filter Search Bar
          SliverToBoxAdapter(
            child: _FilterSearchBar(
              searchQuery: _searchQuery,
              sortOption: _sortOption,
              selectedRange: _selectedDateRange,
              onSearchChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onSortChanged: (val) {
                setState(() {
                  _sortOption = val;
                });
              },
              onDateRangePicked: (range) {
                setState(() {
                  _selectedDateRange = range;
                });
              },
            ),
          ),

          // Shimmer loading
          if (_isLoading)
            const _ShimmerMovementList()
          else if (_pergerakanList.isEmpty || grouped.isEmpty)
            // Empty States matching the specific tab
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildSpecificEmptyState(type),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final mvts = grouped[dateKey]!;

                    // Sum change amounts for this date group
                    int masukSum = 0;
                    int keluarSum = 0;
                    for (var item in mvts) {
                      final int q = item['qty'] as int;
                      if (q > 0) {
                        masukSum += q;
                      } else {
                        keluarSum += q.abs();
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group date header
                        _DateGroupHeader(
                          dateText: dateKey,
                          masukSum: masukSum,
                          keluarSum: keluarSum,
                        ),
                        const SizedBox(height: 8),

                        // List of cards
                        ...mvts.map((mvt) {
                          return Dismissible(
                            key: ValueKey(mvt['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: AppColors.alert.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                                  SizedBox(height: 2),
                                  Text("Hapus & Rollback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              _deleteMovement(mvt);
                              return false; // dismiss handeled dialog
                            },
                            child: _MovementCard(
                              movement: mvt,
                              onTap: () => _openMovementDetail(mvt),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100))
        ],
      ),
    );
  }

  Widget _buildSpecificEmptyState(String type) {
    if (type == "MASUK") {
      return const _EmptyState(
        icon: Icons.arrow_circle_down_outlined,
        title: "Belum Ada Stok Masuk",
        subtitle: "Catat penerimaan produk atau hasil produksi di sini",
      );
    } else if (type == "KELUAR") {
      return const _EmptyState(
        icon: Icons.arrow_circle_up_outlined,
        title: "Belum Ada Stok Keluar",
        subtitle: "Stok keluar tercatat otomatis saat ada penjualan",
      );
    } else if (type == "KOREKSI") {
      return const _EmptyState(
        icon: Icons.edit_note_outlined,
        title: "Belum Ada Koreksi Stok",
        subtitle: "Gunakan koreksi untuk menyesuaikan stok secara manual",
      );
    } else {
      return _EmptyState(
        icon: Icons.swap_vert_outlined,
        title: "Belum Ada Pergerakan Stok",
        subtitle: "Semua keluar masuk stok akan tercatat otomatis di sini",
        ctaLabel: "Catat Pergerakan",
        onCtaPressed: _openCatatPergerakan,
      );
    }
  }
}

// =========================================================================
// 1. HEADER SECTION (SliverAppBar)
// =========================================================================
class _HeaderSection extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _HeaderSection({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: statusBarHeight + 110,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFFB37B50)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32.0),
              bottomRight: Radius.circular(32.0),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20.0, statusBarHeight + 16.0, 20.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pergerakan Stok',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau keluar masuk stok Anda',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onAddPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(150, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: const Text(
                  'Catat Pergerakan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. SUMMARY STRIP WIDGET (4 items)
// =========================================================================
class _SummaryStrip extends StatelessWidget {
  final int masuk;
  final int keluar;
  final int koreksi;
  final int retur;

  const _SummaryStrip({
    required this.masuk,
    required this.keluar,
    required this.koreksi,
    required this.retur,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildItem(
            title: "Masuk Hari Ini",
            value: "+$masuk",
            icon: Icons.arrow_downward_rounded,
            iconBgColor: AppColors.success.withOpacity(0.15),
            iconColor: AppColors.success,
          ),
          const SizedBox(width: 10),
          _buildItem(
            title: "Keluar Hari Ini",
            value: "-$keluar",
            icon: Icons.arrow_upward_rounded,
            iconBgColor: AppColors.alert.withOpacity(0.15),
            iconColor: AppColors.alert,
          ),
          const SizedBox(width: 10),
          _buildItem(
            title: "Penyesuaian",
            value: "$koreksi",
            icon: Icons.tune_rounded,
            iconBgColor: AppColors.warning.withOpacity(0.15),
            iconColor: AppColors.warning,
            subLabel: "koreksi stok",
          ),
          const SizedBox(width: 10),
          _buildItem(
            title: "Retur",
            value: "+$retur",
            icon: Icons.keyboard_return_rounded,
            iconBgColor: Colors.blue.withOpacity(0.15),
            iconColor: Colors.blue,
            subLabel: "produk retur",
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    String? subLabel,
  }) {
    return Container(
      width: 130,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subLabel ?? "item ${iconColor == AppColors.success ? 'masuk' : 'keluar'}",
            style: const TextStyle(fontSize: 8, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. STOCK HEALTH INDICATOR BANNER
// =========================================================================
class _StockHealthIndicator extends StatelessWidget {
  final String message;
  final Color color;

  const _StockHealthIndicator({
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            message.startsWith("✓")
                ? Icons.check_circle_outline_rounded
                : message.startsWith("⚠")
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. FLOW VISUALIZATION WITH MOVING DOT ANIMATION
// =========================================================================
class _FlowVisualization extends StatelessWidget {
  final int masuk;
  final int gudang;
  final int keluar;
  final AnimationController animationController;

  const _FlowVisualization({
    required this.masuk,
    required this.gudang,
    required this.keluar,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = masuk == 0 && keluar == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Alur Stok Hari Ini",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Box MASUK
              _buildBox(
                label: "MASUK",
                val: "$masuk item",
                color: AppColors.success,
                icon: Icons.login_rounded,
              ),

              // Animated connector 1
              Expanded(
                child: _AnimatedConnector(
                  controller: animationController,
                  color: AppColors.success,
                ),
              ),

              // Box GUDANG
              _buildBox(
                label: "GUDANG",
                val: "$gudang item",
                color: AppColors.primary,
                icon: Icons.warehouse_rounded,
                isFilled: true,
              ),

              // Animated connector 2
              Expanded(
                child: _AnimatedConnector(
                  controller: animationController,
                  color: AppColors.alert,
                ),
              ),

              // Box KELUAR
              _buildBox(
                label: "KELUAR",
                val: "$keluar item",
                color: AppColors.alert,
                icon: Icons.logout_rounded,
              ),
            ],
          ),
          if (isEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              "Belum ada pergerakan hari ini",
              style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBox({
    required String label,
    required String val,
    required Color color,
    required IconData icon,
    bool isFilled = false,
  }) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isFilled ? AppColors.secondary.withOpacity(0.7) : Colors.white,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AnimatedConnector extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _AnimatedConnector({
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 12),
          painter: _ConnectorPainter(
            progress: controller.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ConnectorPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw reference dashed line
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);

    // Draw flowing dot moving from start to end
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double cx = size.width * progress;
    final double cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =========================================================================
// SLIVER TAB BAR PERSISTENT DELEGATE
// =========================================================================
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// =========================================================================
// FILTER & SEARCH BAR WIDGET
// =========================================================================
class _FilterSearchBar extends StatelessWidget {
  final String searchQuery;
  final String sortOption;
  final DateTimeRange? selectedRange;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<DateTimeRange?> onDateRangePicked;

  const _FilterSearchBar({
    required this.searchQuery,
    required this.sortOption,
    required this.selectedRange,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onDateRangePicked,
  });

  @override
  Widget build(BuildContext context) {
    final String rangeLabel = selectedRange == null
        ? "Filter Tanggal"
        : "${DateFormat('d MMM').format(selectedRange!.start)} - ${DateFormat('d MMM yyyy').format(selectedRange!.end)}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          // Row with search and date range
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: "Cari produk atau catatan...",
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date Range Button
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 30)),
                    initialDateRange: selectedRange,
                  );
                  if (range != null) {
                    onDateRangePicked(range);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        rangeLabel,
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (selectedRange != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onDateRangePicked(null),
                          child: const Icon(Icons.cancel_rounded, color: AppColors.primary, size: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),

          // Sorting & clear filter options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Urutkan:", style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortOption,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: "Terbaru", child: Text("Terbaru")),
                      DropdownMenuItem(value: "Terlama", child: Text("Terlama")),
                      DropdownMenuItem(value: "Terbanyak", child: Text("Kuantitas Terbanyak")),
                      DropdownMenuItem(value: "Tersedikit", child: Text("Kuantitas Tersedikit")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        onSortChanged(val);
                      }
                    },
                    icon: const Icon(Icons.sort_rounded, color: AppColors.primary, size: 16),
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

// =========================================================================
// DATE GROUP HEADER
// =========================================================================
class _DateGroupHeader extends StatelessWidget {
  final String dateText;
  final int masukSum;
  final int keluarSum;

  const _DateGroupHeader({
    required this.dateText,
    required this.masukSum,
    required this.keluarSum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Row(
            children: [
              if (masukSum > 0)
                Text(
                  "+$masukSum",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              if (masukSum > 0 && keluarSum > 0) const Text(" | ", style: TextStyle(color: Colors.grey, fontSize: 11)),
              if (keluarSum > 0)
                Text(
                  "-$keluarSum",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.alert),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MOVEMENT CARD WIDGET
// =========================================================================
class _MovementCard extends StatelessWidget {
  final Map<String, dynamic> movement;
  final VoidCallback onTap;

  const _MovementCard({
    required this.movement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = movement['type'] as String;
    final int qty = movement['qty'] as int;

    Color color;
    IconData icon;
    String sign = "";
    if (type == "MASUK") {
      color = AppColors.success;
      icon = Icons.arrow_downward_rounded;
      sign = "+";
    } else if (type == "KELUAR") {
      color = AppColors.alert;
      icon = Icons.arrow_upward_rounded;
      sign = "";
    } else if (type == "KOREKSI") {
      color = AppColors.warning;
      icon = Icons.tune_rounded;
      sign = qty > 0 ? "+" : "";
    } else {
      // Retur
      color = Colors.blue;
      icon = Icons.keyboard_return_rounded;
      sign = "+";
    }

    final timeFormatter = DateFormat('HH:mm');
    final timeStr = timeFormatter.format(movement['dateTime'] as DateTime);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.02),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left bar indicator
              Container(width: 5, height: 75, color: color),
              const SizedBox(width: 12),

              // Icon inside circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        type,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Product Name
                    Text(
                      movement['nama'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Notes
                    Text(
                      movement['notes'] as String,
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Timestamp
                    Text(
                      "$timeStr WIB • oleh ${movement['user']}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Amount
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$sign$qty pcs",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Sisa: ${movement['sisa']}",
                      style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// MINI STOCK TIMELINE 7 DAYS (fl_chart)
// =========================================================================
class _StockTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> movements;

  const _StockTimeline({required this.movements});

  @override
  Widget build(BuildContext context) {
    // Generate mini chart counts for last 7 days
    final Map<int, int> inDaily = {};
    final Map<int, int> outDaily = {};
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dateKey = day.day;
      inDaily[dateKey] = 0;
      outDaily[dateKey] = 0;

      for (var item in movements) {
        final d = item['dateTime'] as DateTime;
        if (d.day == day.day && d.month == day.month && d.year == day.year) {
          final int q = item['qty'] as int;
          if (q > 0) {
            inDaily[dateKey] = inDaily[dateKey]! + q;
          } else {
            outDaily[dateKey] = outDaily[dateKey]! + q.abs();
          }
        }
      }
    }

    final daysAbbr = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Timeline 7 Hari Terakhir",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 7) {
                          // Day name abbr
                          final d = today.subtract(Duration(days: 6 - idx));
                          return Text(daysAbbr[d.weekday % 7], style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold));
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  final d = today.subtract(Duration(days: 6 - index));
                  final int key = d.day;
                  final double valIn = (inDaily[key] ?? 0).toDouble();
                  final double valOut = (outDaily[key] ?? 0).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: valIn, color: AppColors.success, width: 6),
                      BarChartRodData(toY: valOut, color: AppColors.alert, width: 6),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// REUSABLE EMPTY STATE
// =========================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.3), shape: BoxShape.circle),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCtaPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(180, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                label: Text(ctaLabel!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// SHIMMER MOVEMENT LIST LOADER
// =========================================================================
class _ShimmerMovementList extends StatelessWidget {
  const _ShimmerMovementList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 75,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 120, height: 12, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(width: 80, height: 10, color: Colors.white),
                          ],
                        ),
                      ),
                      Container(width: 50, height: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: 4,
        ),
      ),
    );
  }
}

// =========================================================================
// BOTTOM SHEET - CATAT PERGERAKAN BARU WIDGET
// =========================================================================
class _NewMovementSheet extends StatefulWidget {
  final List<Map<String, dynamic>> inventory;
  final ValueChanged<Map<String, dynamic>> onConfirm;

  const _NewMovementSheet({
    required this.inventory,
    required this.onConfirm,
  });

  @override
  State<_NewMovementSheet> createState() => _NewMovementSheetState();
}

class _NewMovementSheetState extends State<_NewMovementSheet> {
  int _step = 1; // 1: Pilih Tipe, 2: Detail Form, 3: Konfirmasi / Sukses
  
  String _selectedType = "MASUK"; // MASUK, KELUAR, KOREKSI, RETUR
  String _selectedProductId = "";
  int _quantity = 10;
  
  // Correction specific
  bool _isAddition = true; 
  
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.inventory.isNotEmpty) {
      _selectedProductId = widget.inventory.first['id'] as String;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color get _typeColor {
    if (_selectedType == "MASUK") return AppColors.success;
    if (_selectedType == "KELUAR") return AppColors.alert;
    if (_selectedType == "KOREKSI") return AppColors.warning;
    return Colors.blue;
  }

  String get _notesPlaceholder {
    if (_selectedType == "MASUK") return "Contoh: Produksi batch #001";
    if (_selectedType == "KELUAR") return "Contoh: Penjualan offline";
    if (_selectedType == "KOREKSI") return "Contoh: Hasil stock opname";
    return "Contoh: Produk rusak / salah varian";
  }

  void _saveMovement() {
    final int changeQty = _selectedType == "MASUK" || _selectedType == "RETUR"
        ? _quantity
        : _selectedType == "KELUAR"
            ? -_quantity
            : _isAddition
                ? _quantity
                : -_quantity;

    widget.onConfirm({
      'type': _selectedType,
      'productId': _selectedProductId,
      'qty': changeQty,
      'notes': _notesController.text.trim().isEmpty ? _selectedType : _notesController.text.trim(),
      'dateTime': _selectedDateTime,
    });
    setState(() {
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 16),

          // Title
          if (_step != 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _step == 1 ? "Pilih Tipe Pergerakan" : "Detail Pergerakan",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
                Text(
                  "Langkah $_step/2",
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Steps Content
          Expanded(
            child: _step == 1
                ? _buildStep1Grid()
                : _step == 2
                    ? _buildStep2Form()
                    : _buildStep3Success(),
          ),

          // Footer
          if (_step == 2) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _step = 1;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text("Kembali", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMovement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text("Simpan"),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStep1Grid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildTypeTile("MASUK", "Stok Masuk", Icons.arrow_circle_down_rounded, AppColors.success, "Terima produk atau produksi"),
        _buildTypeTile("KELUAR", "Stok Keluar", Icons.arrow_circle_up_rounded, AppColors.alert, "Produk terjual atau terpakai"),
        _buildTypeTile("KOREKSI", "Penyesuaian", Icons.tune_rounded, AppColors.warning, "Koreksi stok manual"),
        _buildTypeTile("RETUR", "Retur", Icons.keyboard_return_rounded, Colors.blue, "Produk dikembalikan"),
      ],
    );
  }

  Widget _buildTypeTile(String type, String label, IconData icon, Color color, String sub) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _step = 2;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Form() {
    final product = widget.inventory.firstWhere((p) => p['id'] == _selectedProductId);
    final int currentStock = product['stok'] as int;
    final int finalStock = _selectedType == "MASUK" || _selectedType == "RETUR"
        ? currentStock + _quantity
        : _selectedType == "KELUAR"
            ? currentStock - _quantity
            : _isAddition
                ? currentStock + _quantity
                : currentStock - _quantity;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Product dropdown
          const Text("Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedProductId,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
            items: widget.inventory.map((p) {
              return DropdownMenuItem<String>(
                value: p['id'],
                child: Text("${p['nama']} (Sisa: ${p['stok']})"),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedProductId = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Quantity selector with +/-
          const Text("Jumlah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 32, color: AppColors.primary),
                onPressed: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                    });
                  }
                },
              ),
              const SizedBox(width: 20),
              Text(
                "$_quantity",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _typeColor),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 32, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Additional Correction options
          if (_selectedType == "KOREKSI") ...[
            const Text("Jenis Koreksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Tambah (+) Stok")),
                    selected: _isAddition,
                    onSelected: (val) {
                      setState(() {
                        _isAddition = true;
                      });
                    },
                    selectedColor: AppColors.success,
                    labelStyle: TextStyle(color: _isAddition ? Colors.white : AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Kurangi (-) Stok")),
                    selected: !_isAddition,
                    onSelected: (val) {
                      setState(() {
                        _isAddition = false;
                      });
                    },
                    selectedColor: AppColors.alert,
                    labelStyle: TextStyle(color: !_isAddition ? Colors.white : AppColors.alert, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Date time picker row
          const Text("Waktu Pergerakan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDateTime,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                );
                if (time != null && mounted) {
                  setState(() {
                    _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd MMMM yyyy, HH:mm WIB').format(_selectedDateTime)),
                  const Icon(Icons.access_time_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          const Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: _notesPlaceholder,
            ),
          ),
          const SizedBox(height: 20),

          // Preview card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ringkasan Pergerakan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 6),
                Text(
                  "${product['nama']} akan ${_selectedType == 'MASUK' || (_selectedType == 'KOREKSI' && _isAddition) ? 'bertambah' : 'berkurang'} sebanyak $_quantity pcs.",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stok Gudang: $currentStock → $finalStock pcs",
                  style: TextStyle(fontSize: 11, color: finalStock < 0 ? AppColors.alert : AppColors.primary, fontWeight: FontWeight.bold),
                ),
                if (finalStock < 0) ...[
                  const SizedBox(height: 4),
                  const Text("⚠️ Peringatan: Stok akan bernilai negatif!", style: TextStyle(color: AppColors.alert, fontSize: 10, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep3Success() {
    String successMsg = "Catatan pergerakan stok berhasil disimpan!";
    if (_selectedType == "MASUK") successMsg = "Stok Berhasil Ditambahkan! 📦";
    if (_selectedType == "KELUAR") successMsg = "Stok Keluar Tercatat! ✅";
    if (_selectedType == "KOREKSI") successMsg = "Stok Berhasil Disesuaikan! 🔧";
    if (_selectedType == "RETUR") successMsg = "Retur Berhasil Dicatat! 🔄";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated check circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            successMsg,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MOVEMENT DETAIL BOTTOM SHEET
// =========================================================================
class _MovementDetailSheet extends StatelessWidget {
  final Map<String, dynamic> movement;
  final VoidCallback onDelete;

  const _MovementDetailSheet({
    required this.movement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = movement['type'] as String;
    final int qty = movement['qty'] as int;

    Color color;
    IconData icon;
    if (type == "MASUK") {
      color = AppColors.success;
      icon = Icons.arrow_downward_rounded;
    } else if (type == "KELUAR") {
      color = AppColors.alert;
      icon = Icons.arrow_upward_rounded;
    } else if (type == "KOREKSI") {
      color = AppColors.warning;
      icon = Icons.tune_rounded;
    } else {
      color = Colors.blue;
      icon = Icons.keyboard_return_rounded;
    }

    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(movement['dateTime'] as DateTime);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movement['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text("Catatan Pergerakan", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))),
                child: Text(type, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Large visual representation in center header
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 40),
            ),
          ),
          const SizedBox(height: 16),

          // Spec rows
          _buildInfoRow("Produk", movement['nama'] as String),
          const SizedBox(height: 8),
          _buildInfoRow("Jumlah Penyesuaian", "${qty > 0 ? '+' : ''}$qty pcs", valueColor: color),
          const SizedBox(height: 8),
          _buildInfoRow("Stok Sebelum", "${movement['sisaSebelum']} pcs"),
          const SizedBox(height: 8),
          _buildInfoRow("Stok Sesudah", "${movement['sisa']} pcs", isBold: true, valueColor: AppColors.primary),
          const SizedBox(height: 8),
          _buildInfoRow("Waktu Pergerakan", "$dateStr WIB"),
          const SizedBox(height: 8),
          _buildInfoRow("Keterangan", movement['notes'] as String),
          const SizedBox(height: 8),
          _buildInfoRow("Dicatat Oleh", movement['user'] as String),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.alert),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Hapus Catatan", style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold || valueColor != null ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
