import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'app_colors.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Active state lists
  final List<Map<String, dynamic>> _transaksiList = [];
  
  // Mock Inventory products for checkout sheet
  final List<Map<String, dynamic>> _mockInventory = [
    {'id': '1', 'nama': 'Abon Sapi Original 250g', 'hargaJual': 75000, 'hargaModal': 50000, 'stok': 25, 'kategori': 'Abon', 'satuan': 'pcs'},
    {'id': '2', 'nama': 'Abon Sapi Pedas 250g', 'hargaJual': 80000, 'hargaModal': 55000, 'stok': 18, 'kategori': 'Abon', 'satuan': 'pcs'},
    {'id': '3', 'nama': 'Abon Ayam Original 150g', 'hargaJual': 45000, 'hargaModal': 30000, 'stok': 30, 'kategori': 'Abon', 'satuan': 'pcs'},
    {'id': '4', 'nama': 'Abon Ayam Pedas 150g', 'hargaJual': 50000, 'hargaModal': 35000, 'stok': 15, 'kategori': 'Abon', 'satuan': 'pcs'},
    {'id': '5', 'nama': 'Camilan Salakopi Crispy', 'hargaJual': 25000, 'hargaModal': 15000, 'stok': 40, 'kategori': 'Camilan', 'satuan': 'pcs'},
  ];

  // Tab 1 state
  String _selectedPeriod = "Hari Ini"; // Hari Ini, Minggu Ini, Bulan Ini
  String _chartType = "Bar Chart"; // Bar Chart, Line Chart
  bool _isStatsLoading = false;

  // Tab 2 state
  String _searchQuery = "";
  String _selectedHistoryFilter = "Semua"; // Semua, Hari Ini, Minggu Ini, Bulan Ini, Sukses, Dibatalkan

  // Tab 3 state
  String _selectedLaporanPeriod = "Mei 2026";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add Transaction
  void _addTransaction(Map<String, dynamic> newTx) {
    setState(() {
      _transaksiList.insert(0, newTx);
      // Deduct stock from mock inventory
      for (var item in newTx['items']) {
        final invItem = _mockInventory.firstWhere((p) => p['id'] == item['product']['id'], orElse: () => {});
        if (invItem.isNotEmpty) {
          invItem['stok'] = (invItem['stok'] ?? 0) - (item['quantity'] as int);
        }
      }
    });
  }

  // Cancel Transaction
  void _cancelTransaction(String txId) {
    final txIndex = _transaksiList.indexWhere((tx) => tx['id'] == txId);
    if (txIndex != -1) {
      final tx = _transaksiList[txIndex];
      setState(() {
        tx['status'] = "Dibatalkan";
        // Restore stock
        for (var item in tx['items']) {
          final invItem = _mockInventory.firstWhere((p) => p['id'] == item['product']['id'], orElse: () => {});
          if (invItem.isNotEmpty) {
            invItem['stok'] = (invItem['stok'] ?? 0) + (item['quantity'] as int);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi $txId berhasil dibatalkan'),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Trigger loading effect when state changes
  void _triggerStatsLoading() {
    setState(() {
      _isStatsLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isStatsLoading = false;
        });
      }
    });
  }

  // Calculations for period
  List<Map<String, dynamic>> get _filteredTransactionsByPeriod {
    // If no transactions, return empty
    if (_transaksiList.isEmpty) return [];

    // Filter by period selected
    final now = DateTime.now();
    return _transaksiList.where((tx) {
      final date = tx['dateTime'] as DateTime;
      if (_selectedPeriod == "Hari Ini") {
        return date.day == now.day && date.month == now.month && date.year == now.year;
      } else if (_selectedPeriod == "Minggu Ini") {
        final difference = now.difference(date).inDays;
        return difference <= 7;
      } else {
        return date.month == now.month && date.year == now.year;
      }
    }).toList();
  }

  int get _totalRevenue {
    final activeTx = _filteredTransactionsByPeriod.where((tx) => tx['status'] == "Sukses");
    return activeTx.fold(0, (sum, tx) => sum + (tx['total'] as int));
  }

  int get _totalItemsSold {
    final activeTx = _filteredTransactionsByPeriod.where((tx) => tx['status'] == "Sukses");
    int count = 0;
    for (var tx in activeTx) {
      for (var item in tx['items']) {
        count += item['quantity'] as int;
      }
    }
    return count;
  }

  int get _averageTransactionValue {
    final activeTx = _filteredTransactionsByPeriod.where((tx) => tx['status'] == "Sukses").toList();
    if (activeTx.isEmpty) return 0;
    return _totalRevenue ~/ activeTx.length;
  }

  String get _bestProduct {
    final activeTx = _filteredTransactionsByPeriod.where((tx) => tx['status'] == "Sukses");
    final Map<String, int> productSales = {};
    for (var tx in activeTx) {
      for (var item in tx['items']) {
        final name = item['product']['nama'] as String;
        productSales[name] = (productSales[name] ?? 0) + (item['quantity'] as int);
      }
    }
    if (productSales.isEmpty) return "-";
    var best = "";
    var maxSales = 0;
    productSales.forEach((key, value) {
      if (value > maxSales) {
        maxSales = value;
        best = key;
      }
    });
    return best;
  }

  // Top Products details for Ringkasan Tab
  List<Map<String, dynamic>> get _topProducts {
    final activeTx = _transaksiList.where((tx) => tx['status'] == "Sukses");
    final Map<String, Map<String, dynamic>> productStats = {};
    
    for (var tx in activeTx) {
      for (var item in tx['items']) {
        final p = item['product'];
        final id = p['id'] as String;
        final name = p['nama'] as String;
        final qty = item['quantity'] as int;
        final price = p['hargaJual'] as int;

        if (productStats.containsKey(id)) {
          productStats[id]!['sold'] += qty;
          productStats[id]!['revenue'] += qty * price;
        } else {
          productStats[id] = {
            'nama': name,
            'sold': qty,
            'revenue': qty * price,
          };
        }
      }
    }

    final list = productStats.values.toList();
    list.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));
    return list;
  }

  // History Tab Filter
  List<Map<String, dynamic>> get _historyFilteredTransactions {
    final now = DateTime.now();
    return _transaksiList.where((tx) {
      final matchesSearch = tx['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['buyerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tx['items'] as List).any((item) => item['product']['nama'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));

      final date = tx['dateTime'] as DateTime;
      bool matchesPeriod = true;
      if (_selectedHistoryFilter == "Hari Ini") {
        matchesPeriod = date.day == now.day && date.month == now.month && date.year == now.year;
      } else if (_selectedHistoryFilter == "Minggu Ini") {
        matchesPeriod = now.difference(date).inDays <= 7;
      } else if (_selectedHistoryFilter == "Bulan Ini") {
        matchesPeriod = date.month == now.month && date.year == now.year;
      } else if (_selectedHistoryFilter == "Sukses") {
        matchesPeriod = tx['status'] == "Sukses";
      } else if (_selectedHistoryFilter == "Dibatalkan") {
        matchesPeriod = tx['status'] == "Dibatalkan";
      }

      return matchesSearch && matchesPeriod;
    }).toList();
  }

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> get _groupedTransactions {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID'); // Indonesian locale fallback if initialized, else simple date

    for (var tx in _historyFilteredTransactions) {
      final date = tx['dateTime'] as DateTime;
      // Simple date formatting
      final dateStr = _formatDateIndo(date);
      if (groups.containsKey(dateStr)) {
        groups[dateStr]!.add(tx);
      } else {
        groups[dateStr] = [tx];
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

  // Open New Transaction Sheet
  void _openNewTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewTransactionSheet(
        inventory: _mockInventory,
        onConfirm: (txData) {
          _addTransaction(txData);
          _triggerStatsLoading();
        },
      ),
    );
  }

  // Open Details Dialog / Sheet
  void _openTransactionDetail(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionDetailSheet(
        transaction: tx,
        onCancel: () => _cancelTransaction(tx['id'] as String),
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
              // 1. HEADER SECTION (Sticky layout)
              _HeaderSection(
                onAddTransaction: _openNewTransactionSheet,
              ),

              // 2. TAB BAR (Sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.grey.withOpacity(0.15),
                    tabs: const [
                      Tab(text: "Ringkasan"),
                      Tab(text: "Riwayat"),
                      Tab(text: "Laporan"),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1 - RINGKASAN
              _buildRingkasanTab(currencyFormatter),

              // TAB 2 - RIWAYAT
              _buildRiwayatTab(currencyFormatter),

              // TAB 3 - LAPORAN
              _buildLaporanTab(currencyFormatter),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1 - RINGKASAN WIDGETS
  // =========================================================================
  Widget _buildRingkasanTab(NumberFormat formatter) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Period Selector
          _PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onChanged: (val) {
              setState(() {
                _selectedPeriod = val;
                _triggerStatsLoading();
              });
            },
          ),
          const SizedBox(height: 20),

          // Shimmer wrapper for cards & stats
          _isStatsLoading
              ? _buildShimmerSummary()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // B. Hero Revenue Card
                    _HeroRevenueCard(
                      revenue: _totalRevenue,
                      txCount: _filteredTransactionsByPeriod.where((tx) => tx['status'] == "Sukses").length,
                    ),
                    const SizedBox(height: 16),

                    // C. Mini Stats Row
                    _MiniStatsRow(
                      itemsSold: _totalItemsSold,
                      averageTx: _averageTransactionValue,
                      bestProduct: _bestProduct,
                      formatter: formatter,
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // D. Grafik Penjualan
          _buildSalesChartSection(),
          const SizedBox(height: 24),

          // E. Top Produk Section
          _TopProductSection(
            topProducts: _topProducts,
            formatter: formatter,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildShimmerSummary() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 90,
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartSection() {
    final bool isEmpty = _filteredTransactionsByPeriod.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grafik Penjualan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
              ),
              // Chart Toggle option
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ["Bar Chart", "Line Chart"].map((type) {
                    final isSel = _chartType == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _chartType = type;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined, size: 54, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        "Belum ada data penjualan",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Mulai catat transaksi pertama Anda",
                        style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  )
                : _SalesChart(
                    transactions: _filteredTransactionsByPeriod,
                    chartType: _chartType,
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2 - RIWAYAT TRANSAKSI WIDGETS
  // =========================================================================
  Widget _buildRiwayatTab(NumberFormat formatter) {
    final groups = _groupedTransactions;

    return RefreshIndicator(
      onRefresh: () async {
        _triggerStatsLoading();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Filter & Search bar header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: "Cari transaksi atau produk...",
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Filter lanjutan segera hadir!"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: ["Semua", "Hari Ini", "Minggu Ini", "Bulan Ini", "Sukses", "Dibatalkan"].map((filter) {
                        final isSel = _selectedHistoryFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSel ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSel,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedHistoryFilter = filter;
                                });
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Transactions List or Empty state
          _transaksiList.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: "Belum Ada Transaksi",
                    subtitle: "Riwayat transaksi akan muncul di sini",
                    ctaLabel: "Catat Transaksi Pertama",
                    onCtaPressed: _openNewTransactionSheet,
                  ),
                )
              : _historyFilteredTransactions.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: Icons.search_off_rounded,
                        title: "Transaksi Tidak Ditemukan",
                        subtitle: "Ganti kata kunci pencarian atau filter Anda",
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dateKey = groups.keys.elementAt(index);
                            final txs = groups[dateKey]!;

                            // Calculate daily total
                            final dailyTotal = txs.where((tx) => tx['status'] == "Sukses").fold(0, (sum, tx) => sum + (tx['total'] as int));

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Date header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateKey,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        formatter.format(dailyTotal),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Date transactions list
                                ...txs.map((tx) {
                                  return _buildSwipeableTransactionCard(tx, formatter);
                                }).toList(),
                                
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          childCount: groups.length,
                        ),
                      ),
                    ),
          
          // Extra bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          )
        ],
      ),
    );
  }

  Widget _buildSwipeableTransactionCard(Map<String, dynamic> tx, NumberFormat formatter) {
    return Dismissible(
      key: ValueKey(tx['id']),
      direction: tx['status'] == "Sukses" ? DismissDirection.horizontal : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left: cancel transaction
          _cancelTransaction(tx['id'] as String);
          return false; // Don't actually remove widget from tree, just state updates
        } else {
          // Swipe right: open details
          _openTransactionDetail(tx);
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.alert.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
      ),
      child: _TransactionCard(
        transaction: tx,
        formatter: formatter,
        onTap: () => _openTransactionDetail(tx),
      ),
    );
  }

  // =========================================================================
  // TAB 3 - LAPORAN WIDGETS
  // =========================================================================
  Widget _buildLaporanTab(NumberFormat formatter) {
    // Basic sums for report
    final totalPendapatanKotor = _transaksiList
        .where((tx) => tx['status'] == "Sukses")
        .fold(0, (sum, tx) => sum + (tx['total'] as int));

    int totalModal = 0;
    for (var tx in _transaksiList.where((tx) => tx['status'] == "Sukses")) {
      for (var item in tx['items']) {
        final qty = item['quantity'] as int;
        final modal = item['product']['hargaModal'] as int;
        totalModal += qty * modal;
      }
    }

    final labaBersih = totalPendapatanKotor - totalModal;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Period Picker dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Periode Laporan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLaporanPeriod,
                    items: const [
                      DropdownMenuItem(value: "Mei 2026", child: Text("Mei 2026")),
                      DropdownMenuItem(value: "April 2026", child: Text("April 2026")),
                      DropdownMenuItem(value: "Maret 2026", child: Text("Maret 2026")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedLaporanPeriod = val;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // B. Laporan Cards
          _buildReportCard(
            title: "Pendapatan Kotor",
            value: formatter.format(totalPendapatanKotor),
            icon: Icons.payments_outlined,
            iconColor: AppColors.primary,
            subInfo: "Statis dari bulan lalu",
          ),
          const SizedBox(height: 14),

          _buildReportCard(
            title: "Total Pengeluaran Modal",
            value: formatter.format(totalModal),
            icon: Icons.trending_down_rounded,
            iconColor: AppColors.alert,
            subInfo: "Beban modal produk terdaftar",
          ),
          const SizedBox(height: 14),

          // Clean gradient laba bersih card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFFB37B50)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Laba Bersih",
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatter.format(labaBersih),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Estimasi laba bersih periode ini",
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // C. Chart Komparasi (Pendapatan vs Modal 6 Bulan)
          _buildComparisonChart(totalPendapatanKotor, totalModal),
          const SizedBox(height: 24),

          // D. Export buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fitur ekspor PDF segera hadir!"), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.alert),
                  label: const Text("Ekspor PDF", style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.alert),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fitur ekspor Excel segera hadir!"), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.table_chart_rounded, color: AppColors.success),
                  label: const Text("Ekspor Excel", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.success),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String subInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
              ],
            ),
          ),
          Text(subInfo, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(int revenue, int capital) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Pendapatan vs Modal 6 Bulan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: _transaksiList.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_outlined, color: Colors.grey[300], size: 40),
                      const SizedBox(height: 8),
                      const Text("Belum ada data perbandingan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                : BarChart(
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
                              const style = TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold);
                              switch (value.toInt()) {
                                case 0: return const Text("Des", style: style);
                                case 1: return const Text("Jan", style: style);
                                case 2: return const Text("Feb", style: style);
                                case 3: return const Text("Mar", style: style);
                                case 4: return const Text("Apr", style: style);
                                case 5: return const Text("Mei", style: style);
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _makeBarGroup(0, 1200000, 800000),
                        _makeBarGroup(1, 1500000, 950000),
                        _makeBarGroup(2, 900000, 600000),
                        _makeBarGroup(3, 2100000, 1400000),
                        _makeBarGroup(4, 1800000, 1100000),
                        _makeBarGroup(5, revenue.toDouble(), capital.toDouble()),
                      ],
                    ),
                  ),
          ),
          if (_transaksiList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("Pendapatan", AppColors.primary),
                const SizedBox(width: 24),
                _buildLegendItem("Modal", AppColors.secondary),
              ],
            )
          ]
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: AppColors.primary, width: 8, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: y2, color: AppColors.secondary, width: 8, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// 1. HEADER SECTION WIDGET (SliverAppBar)
// =========================================================================
class _HeaderSection extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const _HeaderSection({required this.onAddTransaction});

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
                    'Penjualan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catat & kelola transaksi Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onAddTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(140, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text(
                  'Transaksi Baru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
// TAB 1 - PERIOD SELECTOR
// =========================================================================
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periods = ["Hari Ini", "Minggu Ini", "Bulan Ini"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: periods.map((p) {
        final isAct = selectedPeriod == p;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => onChanged(p),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isAct ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                p,
                style: TextStyle(
                  color: isAct ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =========================================================================
// TAB 1 - HERO REVENUE CARD
// =========================================================================
class _HeroRevenueCard extends StatelessWidget {
  final int revenue;
  final int txCount;

  const _HeroRevenueCard({
    required this.revenue,
    required this.txCount,
  });

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFD4A853)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Pendapatan",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            f.format(revenue),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    revenue > 0 ? "10% dari periode lalu" : "0% dari periode lalu",
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$txCount Transaksi",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
// TAB 1 - MINI STATS ROW WIDGET (3 Cards)
// =========================================================================
class _MiniStatsRow extends StatelessWidget {
  final int itemsSold;
  final int averageTx;
  final String bestProduct;
  final NumberFormat formatter;

  const _MiniStatsRow({
    required this.itemsSold,
    required this.averageTx,
    required this.bestProduct,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildItem(
            title: "Terjual",
            value: "$itemsSold item",
            icon: Icons.shopping_bag_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _buildItem(
            title: "Rata-rata",
            value: formatter.format(averageTx),
            icon: Icons.analytics_rounded,
            color: Colors.blue,
          ),
          const SizedBox(width: 10),
          _buildItem(
            title: "Terbaik",
            value: bestProduct,
            icon: Icons.star_rounded,
            color: AppColors.accent,
            sub: "Produk terlaris",
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? sub,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub ?? title,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 1 - SALES CHART (fl_chart)
// =========================================================================
class _SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String chartType;

  const _SalesChart({
    required this.transactions,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    // Generate simple data based on transaction list times
    final Map<int, double> hourlyRevenue = {};
    for (var tx in transactions.where((tx) => tx['status'] == "Sukses")) {
      final hour = (tx['dateTime'] as DateTime).hour;
      hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0.0) + (tx['total'] as int).toDouble();
    }

    final sortedHours = hourlyRevenue.keys.toList()..sort();
    final spots = sortedHours.map((h) => FlSpot(h.toDouble(), hourlyRevenue[h]!)).toList();

    // Default mock spots if data is low
    final finalSpots = spots.isNotEmpty
        ? spots
        : const [FlSpot(9, 200000), FlSpot(12, 450000), FlSpot(15, 150000), FlSpot(18, 600000)];

    if (chartType == "LineChart" || chartType == "Line Chart") {
      return LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}:00", style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: finalSpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3.5,
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.15)),
            ),
          ],
        ),
      );
    } else {
      // Bar Chart representation
      return BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}:00", style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
          ),
          barGroups: finalSpots.map((spot) {
            return BarChartGroupData(
              x: spot.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: spot.y,
                  color: AppColors.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
        ),
      );
    }
  }
}

// =========================================================================
// TAB 1 - TOP PRODUCT SECTION
// =========================================================================
class _TopProductSection extends StatelessWidget {
  final List<Map<String, dynamic>> topProducts;
  final NumberFormat formatter;

  const _TopProductSection({
    required this.topProducts,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Produk Terlaris",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
          ),
          const SizedBox(height: 16),
          topProducts.isEmpty
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_outlined, color: AppColors.accent, size: 36),
                      const SizedBox(height: 8),
                      Text("Belum ada produk terlaris", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProducts.length > 3 ? 3 : topProducts.length,
                  itemBuilder: (context, index) {
                    final p = topProducts[index];
                    final rankColor = index == 0
                        ? AppColors.accent
                        : index == 1
                            ? Colors.grey
                            : const Color(0xFFCD7F32); // Bronze
                    
                    // Simple progress ratio
                    final int maxSold = topProducts.first['sold'] as int;
                    final double ratio = maxSold > 0 ? (p['sold'] as int) / maxSold : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Product details & progress
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p['nama'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      "${p['sold']} Terjual",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Progress bar
                                LinearProgressIndicator(
                                  value: ratio,
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.secondary.withOpacity(0.5),
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 2 - TRANSACTION CARD
// =========================================================================
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction['status'] as String;
    
    Color statusColor;
    if (status == "Sukses") {
      statusColor = AppColors.success;
    } else if (status == "Dibatalkan") {
      statusColor = AppColors.alert;
    } else {
      statusColor = AppColors.warning;
    }

    final items = transaction['items'] as List;
    final firstItem = items.isNotEmpty ? items.first : {};
    final String itemText = items.length > 1
        ? "${firstItem['product']['nama']} + ${items.length - 1} produk lain"
        : "${firstItem['product']['nama'] ?? ''}";

    final timeFormatter = DateFormat('HH:mm');
    final timeStr = timeFormatter.format(transaction['dateTime'] as DateTime);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.03),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo / Icon placeholder
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),

              // Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction['id'] as String,
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "$timeStr WIB",
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C2C2C)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pembeli: ${transaction['buyerName'].toString().isEmpty ? 'Umum' : transaction['buyerName']}",
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Total and Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(transaction['total']),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// REUSABLE EMPTY STATE WIDGET
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCtaPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(ctaLabel!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// NEW TRANSACTION BOTTOM SHEET
// =========================================================================
class _NewTransactionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> inventory;
  final ValueChanged<Map<String, dynamic>> onConfirm;

  const _NewTransactionSheet({
    required this.inventory,
    required this.onConfirm,
  });

  @override
  State<_NewTransactionSheet> createState() => _NewTransactionSheetState();
}

class _NewTransactionSheetState extends State<_NewTransactionSheet> {
  int _step = 1; // 1: Pilih Produk, 2: Detail Transaksi, 3: Sukses Animasi
  String _searchProductQuery = "";
  final Map<String, int> _selectedProductQuantities = {}; // id -> quantity
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _buyerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedPaymentMethod = "Tunai"; // Tunai, Transfer, QRIS
  String _generatedTxId = "";

  List<Map<String, dynamic>> get _filteredInventory {
    return widget.inventory.where((p) {
      return p['nama'].toString().toLowerCase().contains(_searchProductQuery.toLowerCase());
    }).toList();
  }

  int get _cartTotal {
    int total = 0;
    _selectedProductQuantities.forEach((id, qty) {
      final p = widget.inventory.firstWhere((item) => item['id'] == id);
      total += qty * (p['hargaJual'] as int);
    });
    return total;
  }

  int get _cartItemCount {
    return _selectedProductQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  void _confirmTransaction() {
    final List<Map<String, dynamic>> items = [];
    _selectedProductQuantities.forEach((id, qty) {
      final p = widget.inventory.firstWhere((item) => item['id'] == id);
      items.add({
        'product': p,
        'quantity': qty,
      });
    });

    final txId = "TRX-${1000 + DateTime.now().millisecond}";
    final txData = {
      'id': txId,
      'dateTime': DateTime.now(),
      'items': items,
      'buyerName': _buyerNameController.text.trim(),
      'notes': _notesController.text.trim(),
      'paymentMethod': _selectedPaymentMethod,
      'total': _cartTotal,
      'status': "Sukses",
    };

    widget.onConfirm(txData);
    setState(() {
      _generatedTxId = txId;
      _step = 3;
    });
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 16),

          // Header
          if (_step != 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _step == 1 ? "Pilih Produk" : "Detail Transaksi",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
                Text(
                  _step == 1 ? "Langkah 1/2" : "Langkah 2/2",
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Step content
          Expanded(
            child: _step == 1
                ? _buildStep1List(formatter)
                : _step == 2
                    ? _buildStep2Form(formatter)
                    : _buildStep3Success(formatter),
          ),

          // Footer buttons for Step 1 and 2
          if (_step == 1) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_cartItemCount produk dipilih", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      Text(formatter.format(_cartTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _cartItemCount > 0
                        ? () {
                            setState(() {
                              _step = 2;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(120, 48),
                    ),
                    child: const Text("Lanjut"),
                  ),
                ],
              ),
            ),
          ] else if (_step == 2) ...[
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
                    onPressed: _confirmTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text("Konfirmasi"),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStep1List(NumberFormat formatter) {
    return Column(
      children: [
        // Product search
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchProductQuery = val;
              });
            },
            decoration: const InputDecoration(
              hintText: "Cari nama produk...",
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Product list view
        Expanded(
          child: _filteredInventory.isEmpty
              ? Center(child: Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredInventory.length,
                  itemBuilder: (context, index) {
                    final p = _filteredInventory[index];
                    final id = p['id'] as String;
                    final qtySelected = _selectedProductQuantities[id] ?? 0;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.dining_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatter.format(p['hargaJual']),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text("Stok: ${p['stok']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                            // Quantity selector
                            Row(
                              children: [
                                if (qtySelected > 0) ...[
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                                    onPressed: () {
                                      setState(() {
                                        if (qtySelected == 1) {
                                          _selectedProductQuantities.remove(id);
                                        } else {
                                          _selectedProductQuantities[id] = qtySelected - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text("$qtySelected", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                  onPressed: () {
                                    if (qtySelected < (p['stok'] as int)) {
                                      setState(() {
                                        _selectedProductQuantities[id] = qtySelected + 1;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Batas stok tercapai!"), behavior: SnackBarBehavior.floating),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildStep2Form(NumberFormat formatter) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // List of selected items summary
            const Text("Ringkasan Belanja", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _selectedProductQuantities.entries.map((entry) {
                  final p = widget.inventory.firstWhere((item) => item['id'] == entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${p['nama']} (x${entry.value})", style: const TextStyle(fontSize: 13)),
                        Text(formatter.format((p['hargaJual'] as int) * entry.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Buyer Name
            TextFormField(
              controller: _buyerNameController,
              decoration: const InputDecoration(
                labelText: "Nama Pembeli (Opsional)",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Catatan (Opsional)",
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentMethodButton("Tunai", Icons.money_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodButton("Transfer", Icons.account_balance_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodButton("QRIS", Icons.qr_code_2_rounded),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String method, IconData icon) {
    final isSel = _selectedPaymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.white,
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? Colors.white : AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                method,
                style: TextStyle(
                  color: isSel ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3Success(NumberFormat formatter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated check circle (success icon animation alternative)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Transaksi Berhasil Dicatat!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text("Nomor Transaksi: $_generatedTxId", style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          const SizedBox(height: 28),

          // Option buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      // Reset sheet for another transaction
                      _step = 1;
                      _selectedProductQuantities.clear();
                      _buyerNameController.clear();
                      _notesController.clear();
                      _selectedPaymentMethod = "Tunai";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Transaksi Baru", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Lihat Riwayat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// =========================================================================
// TRANSACTION DETAIL BOTTOM SHEET
// =========================================================================
class _TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onCancel;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction['status'] as String;
    final total = transaction['total'] as int;
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    Color statusColor;
    if (status == "Sukses") {
      statusColor = AppColors.success;
    } else if (status == "Dibatalkan") {
      statusColor = AppColors.alert;
    } else {
      statusColor = AppColors.warning;
    }

    final date = transaction['dateTime'] as DateTime;
    final dateStr = DateFormat('d MMMM yyyy, HH:mm').format(date);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
                  Text(transaction['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Items Purchased list
          const Text("Produk Yang Dibeli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: (transaction['items'] as List).length,
              itemBuilder: (context, index) {
                final item = (transaction['items'] as List)[index];
                final p = item['product'];
                final qty = item['quantity'] as int;
                final price = p['hargaJual'] as int;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text("$qty x ${f.format(price)}", style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ),
                      Text(f.format(qty * price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 24),

          // Payment details
          _buildInfoRow("Metode Pembayaran", transaction['paymentMethod'] as String),
          const SizedBox(height: 6),
          _buildInfoRow("Nama Pembeli", transaction['buyerName'].toString().isEmpty ? 'Umum' : transaction['buyerName'] as String),
          const SizedBox(height: 6),
          _buildInfoRow("Catatan", transaction['notes'].toString().isEmpty ? '-' : transaction['notes'] as String),
          
          const Divider(height: 32),

          // Total display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(f.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
            ],
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              if (status == "Sukses") ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.alert),
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Batalkan Transaksi", style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mencetak Struk..."), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  label: const Text("Cetak Struk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
      ],
    );
  }
}
