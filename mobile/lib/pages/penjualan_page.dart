import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({super.key});

  @override
  State<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // State Variables
  bool _isLoadingSales = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _salesList = [];
  List<Map<String, dynamic>> _productList = [];
  String _selectedPeriod = "Hari Ini"; // Hari Ini | Minggu Ini | Bulan Ini
  String _selectedHistoryFilter = "Semua"; // Semua | Hari Ini | Minggu Ini | Bulan Ini | Sukses | Dibatalkan
  String _historySearchQuery = "";
  String _selectedLaporanPeriod = ""; // e.g. "Mei 2026"
  bool _isLineChart = false; // Toggle chart style

  // Form search controller for transaction history
  final TextEditingController _searchController = TextEditingController();

  // App Colors Constants
  static const Color colorPrimary = Color(0xFF8B5E3C);
  static const Color colorSecondary = Color(0xFFF5E6D3);
  static const Color colorAccent = Color(0xFFD4A853);
  static const Color colorBackground = Colors.white;
  static const Color colorSuccess = Color(0xFF4CAF50);
  static const Color colorAlert = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedLaporanPeriod = _getCurrentLaporanPeriod();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getCurrentLaporanPeriod() {
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchSales(),
      _fetchProducts(),
    ]);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/sales'), headers: headers);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success']) {
          setState(() {
            _salesList = List<Map<String, dynamic>>.from(resBody['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching sales: $e");
    } finally {
      setState(() => _isLoadingSales = false);
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/products'), headers: headers);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success']) {
          setState(() {
            _productList = List<Map<String, dynamic>>.from(resBody['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _cancelTransaction(String saleId, String invoiceNumber) async {
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sales/$saleId/cancel'),
        headers: headers,
      );

      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200 && resBody['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Transaksi #$invoiceNumber berhasil dibatalkan"),
            backgroundColor: colorAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadInitialData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? "Gagal membatalkan transaksi"),
            backgroundColor: colorAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchSales(); // reload to reset dismiss state
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: colorAlert,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchSales();
    }
  }

  // --- STATS COMPUTATION FOR TAB 1 & 3 ---
  List<Map<String, dynamic>> _getFilteredSalesByPeriod(String period) {
    final now = DateTime.now();
    return _salesList.where((sale) {
      if (sale['status'] == 'cancelled') return false;
      final createdAt = DateTime.parse(sale['created_at']);

      if (period == "Hari Ini") {
        return createdAt.day == now.day && createdAt.month == now.month && createdAt.year == now.year;
      } else if (period == "Minggu Ini") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      } else if (period == "Bulan Ini") {
        return createdAt.month == now.month && createdAt.year == now.year;
      }
      return true;
    }).toList();
  }

  int _calculateTotalRevenue(List<Map<String, dynamic>> filteredSales) {
    return filteredSales.fold(0, (sum, sale) => sum + (sale['total_price'] as int));
  }

  int _calculateTotalQuantitySold(List<Map<String, dynamic>> filteredSales) {
    int totalQty = 0;
    for (var sale in filteredSales) {
      if (sale['items'] != null) {
        for (var item in sale['items']) {
          totalQty += (item['quantity'] as int);
        }
      }
    }
    return totalQty;
  }

  int _calculateAverageRevenue(List<Map<String, dynamic>> filteredSales) {
    if (filteredSales.isEmpty) return 0;
    return (_calculateTotalRevenue(filteredSales) / filteredSales.length).round();
  }

  Map<String, dynamic> _getBestSellingProduct(List<Map<String, dynamic>> filteredSales) {
    Map<int, int> productQuantities = {};
    Map<int, String> productNames = {};

    for (var sale in filteredSales) {
      if (sale['items'] != null) {
        for (var item in sale['items']) {
          final pId = item['product_id'] as int;
          final qty = item['quantity'] as int;
          final pName = item['product'] != null ? item['product']['name'] as String : "Produk #${pId}";

          productQuantities[pId] = (productQuantities[pId] ?? 0) + qty;
          productNames[pId] = pName;
        }
      }
    }

    if (productQuantities.isEmpty) {
      return {'name': '-', 'quantity': 0};
    }

    int bestProductId = -1;
    int maxQty = -1;
    productQuantities.forEach((id, qty) {
      if (qty > maxQty) {
        maxQty = qty;
        bestProductId = id;
      }
    });

    return {
      'name': productNames[bestProductId] ?? '-',
      'quantity': maxQty
    };
  }

  List<Map<String, dynamic>> _getTopProductsList(List<Map<String, dynamic>> filteredSales) {
    Map<int, Map<String, dynamic>> productStats = {};

    for (var sale in filteredSales) {
      if (sale['items'] != null) {
        for (var item in sale['items']) {
          final pId = item['product_id'] as int;
          final qty = item['quantity'] as int;
          final price = item['price'] as int;
          final pName = item['product'] != null ? item['product']['name'] as String : "Produk #${pId}";

          if (!productStats.containsKey(pId)) {
            productStats[pId] = {
              'product_id': pId,
              'name': pName,
              'quantity': 0,
              'revenue': 0,
            };
          }

          productStats[pId]!['quantity'] += qty;
          productStats[pId]!['revenue'] += (price * qty);
        }
      }
    }

    final list = productStats.values.toList();
    list.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    return list;
  }

  // --- RENDERING WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. HEADER SECTION
            SliverAppBar(
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: colorPrimary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorPrimary, Color(0xFF5C3C24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Penjualan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Catat & kelola transaksi Anda",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // + Transaksi Baru Button
                            ElevatedButton.icon(
                              onPressed: () => _openNewTransactionSheet(),
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                                color: colorPrimary,
                              ),
                              label: const Text(
                                "Transaksi Baru",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. STICKY TAB BAR
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: colorPrimary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: colorAccent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
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
            _buildRingkasanTab(),
            _buildRiwayatTab(),
            _buildLaporanTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1 - RINGKASAN
  // ==========================================
  Widget _buildRingkasanTab() {
    final filteredSales = _getFilteredSalesByPeriod(_selectedPeriod);
    final revenue = _calculateTotalRevenue(filteredSales);
    final transactionsCount = filteredSales.length;
    final qtySold = _calculateTotalQuantitySold(filteredSales);
    final avgRev = _calculateAverageRevenue(filteredSales);
    final bestProduct = _getBestSellingProduct(filteredSales);
    final topProducts = _getTopProductsList(filteredSales);

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. PERIOD SELECTOR
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          // B. HERO REVENUE CARD
          _buildHeroRevenueCard(revenue, transactionsCount, currencyFormat),
          const SizedBox(height: 16),

          // C. MINI STATS ROW
          _buildMiniStatsRow(qtySold, avgRev, bestProduct, currencyFormat),
          const SizedBox(height: 24),

          // D. GRAFIK PENJUALAN
          _buildSalesChartSection(),
          const SizedBox(height: 24),

          // E. TOP PRODUK SECTION
          _buildTopProductSection(topProducts, currencyFormat),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ["Hari Ini", "Minggu Ini", "Bulan Ini"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: periods.map((period) {
        final isActive = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: ChoiceChip(
            label: Text(
              period,
              style: TextStyle(
                color: isActive ? Colors.white : colorPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            selected: isActive,
            selectedColor: colorPrimary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: colorPrimary, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedPeriod = period;
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeroRevenueCard(int revenue, int transactionsCount, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [colorPrimary, Color(0xFFD4A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Pendapatan",
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            format.format(revenue),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "0% dari periode lalu",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$transactionsCount Transaksi",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatsRow(int qtySold, int avgRev, Map<String, dynamic> bestProduct, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            title: "Terjual",
            value: "$qtySold item",
            icon: Icons.shopping_bag_rounded,
            iconColor: colorPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniCard(
            title: "Rata-rata",
            value: format.format(avgRev),
            icon: Icons.analytics_rounded,
            iconColor: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniCard(
            title: "Terbaik",
            value: bestProduct['name'],
            icon: Icons.star_rounded,
            iconColor: colorAccent,
            subtitle: "Produk terlaris",
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            subtitle ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grafik Penjualan",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              // Chart Toggle button
              InkWell(
                onTap: () {
                  setState(() {
                    _isLineChart = !_isLineChart;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isLineChart ? "Line Chart" : "Bar Chart",
                    style: const TextStyle(fontSize: 10, color: colorPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Empty State Chart
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
                    "Belum ada data penjualan",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mulai catat transaksi pertama Anda",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductSection(List<Map<String, dynamic>> topProducts, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Produk Terlaris",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 40, color: colorAccent),
                  SizedBox(height: 10),
                  Text(
                    "Belum ada produk terlaris",
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length > 5 ? 5 : topProducts.length,
              itemBuilder: (context, index) {
                final item = topProducts[index];
                final pName = item['name'];
                final qty = item['quantity'];
                final revenue = item['revenue'];

                // Top ranking colors
                Color rankColor = Colors.grey.shade400;
                if (index == 0) rankColor = colorAccent; // Emas
                if (index == 1) rankColor = const Color(0xFFC0C0C0); // Perak
                if (index == 2) rankColor = const Color(0xFFCD7F32); // Perunggu

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      // Badge
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: rankColor,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  format.format(revenue),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("$qty terjual", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                // Small dummy progress bar
                                Container(
                                  width: 80,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: (80 * (qty / (topProducts[0]['quantity'] as int))).toDouble(),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colorPrimary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
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

  // ==========================================
  // TAB 2 - RIWAYAT TRANSAKSI
  // ==========================================
  Widget _buildRiwayatTab() {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Apply search & filter
    final filteredHistory = _salesList.where((sale) {
      // 1. Search Query
      if (_historySearchQuery.isNotEmpty) {
        final inv = sale['invoice_number'].toString().toLowerCase();
        final cust = (sale['customer_name'] ?? "").toString().toLowerCase();
        if (!inv.contains(_historySearchQuery.toLowerCase()) &&
            !cust.contains(_historySearchQuery.toLowerCase())) {
          return false;
        }
      }

      // 2. Period Filter
      final createdAt = DateTime.parse(sale['created_at']);
      final now = DateTime.now();

      if (_selectedHistoryFilter == "Hari Ini") {
        if (!(createdAt.day == now.day && createdAt.month == now.month && createdAt.year == now.year)) {
          return false;
        }
      } else if (_selectedHistoryFilter == "Minggu Ini") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        if (createdAt.isBefore(startOfWeek.subtract(const Duration(seconds: 1)))) {
          return false;
        }
      } else if (_selectedHistoryFilter == "Bulan Ini") {
        if (!(createdAt.month == now.month && createdAt.year == now.year)) {
          return false;
        }
      } else if (_selectedHistoryFilter == "Sukses") {
        if (sale['status'] != 'success') return false;
      } else if (_selectedHistoryFilter == "Dibatalkan") {
        if (sale['status'] != 'cancelled') return false;
      }

      return true;
    }).toList();

    // Group sales by date
    Map<String, List<Map<String, dynamic>>> groupedSales = {};
    for (var sale in filteredHistory) {
      final dateStr = _formatGroupDate(sale['created_at']);
      if (!groupedSales.containsKey(dateStr)) {
        groupedSales[dateStr] = [];
      }
      groupedSales[dateStr]!.add(sale);
    }

    return Column(
      children: [
        // A. FILTER & SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari transaksi...",
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _historySearchQuery = "";
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _historySearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: colorPrimary, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),

        // Horizontal filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: ["Semua", "Hari Ini", "Minggu Ini", "Bulan Ini", "Sukses", "Dibatalkan"].map((filter) {
              final isActive = _selectedHistoryFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade700,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                  selected: isActive,
                  selectedColor: colorPrimary,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: isActive ? colorPrimary : Colors.transparent, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedHistoryFilter = filter;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // B. TRANSACTION LIST / EMPTY STATE
        Expanded(
          child: _isLoadingSales
              ? _buildShimmerLoader()
              : filteredHistory.isEmpty
                  ? _buildEmptyStateHistory()
                  : RefreshIndicator(
                      onRefresh: _fetchSales,
                      color: colorPrimary,
                      child: ListView.builder(
                        itemCount: groupedSales.keys.length,
                        itemBuilder: (context, dateIndex) {
                          final dateKey = groupedSales.keys.elementAt(dateIndex);
                          final salesForDate = groupedSales[dateKey]!;

                          int totalForDay = salesForDate.fold(0, (sum, sale) {
                            if (sale['status'] == 'cancelled') return sum;
                            return sum + (sale['total_price'] as int);
                          });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date group header
                              _buildDateGroupHeader(dateKey, totalForDay, currencyFormat),
                              // Transactions under this date
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: salesForDate.length,
                                itemBuilder: (context, index) {
                                  final sale = salesForDate[index];
                                  return _buildSwipeableTransactionCard(sale, currencyFormat);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatGroupDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Hari Ini - " + DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  Widget _buildDateGroupHeader(String label, int total, NumberFormat format) {
    return Container(
      width: double.infinity,
      color: colorSecondary.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary),
          ),
          Text(
            "Total: ${format.format(total)}",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableTransactionCard(Map<String, dynamic> sale, NumberFormat format) {
    final saleId = sale['id'].toString();
    final invoice = sale['invoice_number'];
    final customer = sale['customer_name'] ?? "Pelanggan Umum";
    final total = sale['total_price'] as int;
    final time = DateFormat('HH:mm').format(DateTime.parse(sale['created_at']));
    final status = sale['status'];
    final itemsCount = sale['items'] != null ? (sale['items'] as List).length : 0;
    final itemsStr = itemsCount > 0
        ? "${sale['items'][0]['product']?['name'] ?? 'Item'} x ${sale['items'][0]['quantity']}"
        : "-";
    final extraCount = itemsCount > 1 ? " (+${itemsCount - 1} produk)" : "";

    return Dismissible(
      key: Key("sale_$saleId"),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left -> Cancel
          if (status == 'cancelled') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transaksi ini sudah dibatalkan")),
            );
            return false;
          }

          // Show confirmation
          bool cancelConfirmed = false;
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Batalkan Transaksi"),
              content: Text("Apakah Anda yakin ingin membatalkan transaksi #$invoice? Stok produk akan dikembalikan."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
                TextButton(
                  onPressed: () {
                    cancelConfirmed = true;
                    Navigator.pop(context);
                  },
                  child: const Text("Batalkan", style: TextStyle(color: colorAlert)),
                ),
              ],
            ),
          );

          if (cancelConfirmed) {
            _cancelTransaction(saleId, invoice);
            return true;
          }
          return false;
        } else {
          // Swipe Right -> View Details
          _openTransactionDetailSheet(sale);
          return false; // Don't remove the card
        }
      },
      // Swipe Right -> View Details
      background: Container(
        color: colorPrimary.withOpacity(0.9),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.visibility_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text("Detail", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // Swipe Left -> Cancel Transaction
      secondaryBackground: Container(
        color: colorAlert,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Batalkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.cancel_outlined, color: Colors.white),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => _openTransactionDetailSheet(sale),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Lead Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: status == 'cancelled'
                      ? colorAlert.withOpacity(0.08)
                      : colorPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: status == 'cancelled' ? colorAlert : colorPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice,
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "$time WIB",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$itemsStr$extraCount",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Total & Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    format.format(total),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorPrimary),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    if (status == 'success') {
      bg = colorSuccess.withOpacity(0.12);
      text = colorSuccess;
      label = "Sukses";
    } else if (status == 'cancelled') {
      bg = colorAlert.withOpacity(0.12);
      text = colorAlert;
      label = "Dibatalkan";
    } else {
      bg = Colors.orange.withOpacity(0.12);
      text = Colors.orange;
      label = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 8, width: 80, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 140, color: Colors.white),
                    ],
                  ),
                ),
                Container(height: 12, width: 60, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorSecondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 54,
                color: colorPrimary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Belum Ada Transaksi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              "Riwayat transaksi akan muncul di sini",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openNewTransactionSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Catat Transaksi Pertama"),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3 - LAPORAN
  // ==========================================
  Widget _buildLaporanTab() {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. PERIOD PICKER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Laporan Periode",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              InkWell(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: colorPrimary),
                      const SizedBox(width: 8),
                      Text(
                        _selectedLaporanPeriod,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // B. LAPORAN CARDS (VERTIKAL)
          // 1. Pendapatan Kotor
          _buildLaporanCard(
            title: "Pendapatan Kotor",
            value: currencyFormat.format(_calculateTotalRevenue(_getFilteredSalesByPeriod("Bulan Ini"))),
            icon: Icons.monetization_on_outlined,
            iconColor: colorPrimary,
            sub: "perbandingan bulan lalu: - 0%",
          ),
          const SizedBox(height: 12),

          // 2. Total Pengeluaran Modal
          _buildLaporanCard(
            title: "Total Pengeluaran Modal",
            value: "Rp 0",
            icon: Icons.trending_down,
            iconColor: colorAlert,
            sub: "Estimasi modal beli bahan baku",
          ),
          const SizedBox(height: 12),

          // 3. Laba Bersih (Gradient)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [colorPrimary, Color(0xFFD4A853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(_calculateTotalRevenue(_getFilteredSalesByPeriod("Bulan Ini"))),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Estimasi laba bersih bulan ini",
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // C. CHART KOMPARASI (EMPTY STATE)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pendapatan vs Modal 6 Bulan",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 20),
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
                          size: 44,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Belum ada data komparasi",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // D. TOMBOL EKSPOR
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _triggerExportSnackbar(),
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: colorAlert, size: 18),
                  label: const Text("Ekspor PDF", style: TextStyle(color: colorAlert, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: colorAlert),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _triggerExportSnackbar(),
                  icon: const Icon(Icons.table_chart_rounded, color: colorSuccess, size: 18),
                  label: const Text("Ekspor Excel", style: TextStyle(color: colorSuccess, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: colorSuccess),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _triggerExportSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fitur ekspor segera hadir!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // TRANSACTION DETAIL SHEET (BOTTOM SHEET)
  // ==========================================
  void _openTransactionDetailSheet(Map<String, dynamic> sale) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final invoice = sale['invoice_number'];
    final status = sale['status'];
    final timeStr = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(sale['created_at']));
    final customer = sale['customer_name'] ?? "Pelanggan Umum";
    final notes = sale['notes'] ?? "-";
    final payment = sale['payment_method'].toString().toUpperCase();
    final subtotal = sale['subtotal'] as int;
    final discount = sale['discount'] as int;
    final total = sale['total_price'] as int;
    final items = sale['items'] != null ? sale['items'] as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  // Pull Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header with Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const Divider(height: 24),

                  // Details List
                  const Text("Detail Pembeli", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(customer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  const Text("Catatan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(notes, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const Divider(height: 28),

                  // Items List
                  const Text("Produk Dibel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final pName = item['product'] != null ? item['product']['name'] : "Produk #${item['product_id']}";
                      final qty = item['quantity'] as int;
                      final price = item['price'] as int;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("$qty x ${currencyFormat.format(price)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Text(currencyFormat.format(price * qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 28),

                  // Subtotal, Diskon, Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Diskon", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("- " + currencyFormat.format(discount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorAlert)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Bayar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(currencyFormat.format(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metode Bayar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Metode Pembayaran", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Print / Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fitur cetak struk segera hadir!")),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text("Cetak Struk", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      if (status != 'cancelled') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelTransaction(sale['id'].toString(), invoice);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorAlert,
                              side: const BorderSide(color: colorAlert),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Batalkan", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // NEW TRANSACTION BOTTOM SHEET
  // ==========================================
  void _openNewTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NewTransactionSheet(
          productList: _productList,
          onTransactionSuccess: () {
            _loadInitialData();
            // Switch to Riwayat Tab
            _tabController.animateTo(1);
          },
        );
      },
    );
  }
}

// Delegate helper for sticky tab bar header
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ==========================================
// CUSTOM NEW TRANSACTION STATEFUL SHEET
// ==========================================
class _NewTransactionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> productList;
  final VoidCallback onTransactionSuccess;

  const _NewTransactionSheet({
    required this.productList,
    required this.onTransactionSuccess,
  });

  @override
  State<_NewTransactionSheet> createState() => _NewTransactionSheetState();
}

class _NewTransactionSheetState extends State<_NewTransactionSheet> with SingleTickerProviderStateMixin {
  int _currentStep = 1; // Step 1: Select products, Step 2: Details/Form, Step 3: Success

  // Step 1: Selection Map (productId -> quantity selected)
  final Map<int, int> _selectedQuantities = {};
  String _productSearchQuery = "";

  // Step 2: Form controllers
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _discountController = TextEditingController(text: "0");
  final _notesController = TextEditingController();
  String _paymentMethod = "cash"; // cash | transfer | qris
  bool _isSubmitting = false;

  // Step 3: Success result
  String _successInvoice = "";

  // Animation controller for checkmark
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _calculateSubtotal() {
    int sub = 0;
    _selectedQuantities.forEach((id, qty) {
      final product = widget.productList.firstWhere((p) => p['id'] == id);
      sub += ((product['price'] as int) * qty);
    });
    return sub;
  }

  int _calculateTotal() {
    final sub = _calculateSubtotal();
    final disc = int.tryParse(_discountController.text.trim()) ?? 0;
    final total = sub - disc;
    return total < 0 ? 0 : total;
  }

  Future<void> _submitTransaction() async {
    setState(() => _isSubmitting = true);

    try {
      final baseUrl = await AuthService.getBaseUrl();
      final token = await AuthService().getToken();

      // Format payload
      List<Map<String, dynamic>> itemsPayload = [];
      _selectedQuantities.forEach((pId, qty) {
        itemsPayload.add({
          'product_id': pId,
          'quantity': qty,
        });
      });

      final payload = {
        'customer_name': _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
        'discount': int.tryParse(_discountController.text.trim()) ?? 0,
        'payment_method': _paymentMethod,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'items': itemsPayload,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 201 && resBody['success']) {
        setState(() {
          _successInvoice = resBody['data']['invoice_number'];
          _currentStep = 3; // Go to Success Step
        });
        _animationController.forward(from: 0.0);
        widget.onTransactionSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? "Gagal menyimpan transaksi"),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi gagal: $e"),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Pull Bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step Title Header
              if (_currentStep == 1) ...[
                const Text(
                  "Pilih Produk",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                ),
                const SizedBox(height: 2),
                const Text("Pilih produk yang dibeli pelanggan", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ] else if (_currentStep == 2) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF8B5E3C)),
                      onPressed: () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                    ),
                    const Text(
                      "Detail Transaksi",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox.shrink(),
              ],
              const Divider(height: 18),

              // Expanded Flow Screen
              Expanded(
                child: _buildFlowBody(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlowBody(ScrollController scrollController) {
    if (_currentStep == 1) {
      return _buildStep1SelectProducts(scrollController);
    } else if (_currentStep == 2) {
      return _buildStep2FormDetails(scrollController);
    } else {
      return _buildStep3Success();
    }
  }

  // --- STEP 1: SELECT PRODUCTS ---
  Widget _buildStep1SelectProducts(ScrollController scrollController) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Filter product list based on search query
    final filteredProducts = widget.productList.where((product) {
      final name = product['name'].toString().toLowerCase();
      final sku = product['sku'].toString().toLowerCase();
      return name.contains(_productSearchQuery.toLowerCase()) || sku.contains(_productSearchQuery.toLowerCase());
    }).toList();

    int totalSelected = 0;
    _selectedQuantities.forEach((k, v) => totalSelected += v);

    return Column(
      children: [
        // Product Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: "Cari produk dari inventaris...",
            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (val) {
            setState(() {
              _productSearchQuery = val;
            });
          },
        ),
        const SizedBox(height: 12),

        // Product list builder
        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text("Tidak ada produk ditemukan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final pId = product['id'] as int;
                    final pName = product['name'];
                    final pSku = product['sku'];
                    final price = product['price'] as int;
                    final stock = product['stock'] as int;
                    final unit = product['unit'] ?? "pcs";

                    final selectedQty = _selectedQuantities[pId] ?? 0;

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Product Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5E3C).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.dinner_dining, color: Color(0xFF8B5E3C), size: 24),
                            ),
                            const SizedBox(width: 14),

                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "SKU: $pSku • Stok: $stock $unit",
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(price),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Selector
                            if (selectedQty == 0)
                              ElevatedButton(
                                onPressed: stock <= 0
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedQuantities[pId] = 1;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5E3C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: const Text("Pilih", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B5E3C), size: 22),
                                    onPressed: () {
                                      setState(() {
                                        if (selectedQty == 1) {
                                          _selectedQuantities.remove(pId);
                                        } else {
                                          _selectedQuantities[pId] = selectedQty - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    "$selectedQty",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B5E3C), size: 22),
                                    onPressed: selectedQty >= stock
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Batas stok tercapai"),
                                                duration: Duration(milliseconds: 800),
                                              ),
                                            );
                                          }
                                        : () {
                                            setState(() {
                                              _selectedQuantities[pId] = selectedQty + 1;
                                            });
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
        ),

        // Sticky Bottom cart bar
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$totalSelected Produk Dipilih",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(_calculateSubtotal()),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: totalSelected == 0
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 2;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STEP 2: DETAILS FORM ---
  Widget _buildStep2FormDetails(ScrollController scrollController) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Form(
      key: _formKey,
      child: ListView(
        controller: scrollController,
        children: [
          // Selected items summary list
          const Text("Produk Dipilih", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedQuantities.keys.length,
              itemBuilder: (context, index) {
                final id = _selectedQuantities.keys.elementAt(index);
                final qty = _selectedQuantities[id]!;
                final product = widget.productList.firstWhere((p) => p['id'] == id);
                final pName = product['name'];
                final price = product['price'] as int;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$pName x $qty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(currencyFormat.format(price * qty), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Fields
          TextFormField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: "Nama Pembeli (Opsional)",
              prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF8B5E3C)),
              hintText: "e.g. Budi, Ani",
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Diskon (Rp)",
              prefixIcon: Icon(Icons.discount_outlined, color: Color(0xFF8B5E3C)),
            ),
            onChanged: (val) {
              setState(() {}); // trigger total recompute
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: "Catatan (Opsional)",
              prefixIcon: Icon(Icons.edit_note_outlined, color: Color(0xFF8B5E3C)),
              hintText: "Tambahkan catatan transaksi...",
            ),
          ),
          const SizedBox(height: 20),

          // Payment method toggle selector
          const Text("Metode Pembayaran", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPaymentPill("cash", Icons.money_rounded, "Tunai"),
              const SizedBox(width: 8),
              _buildPaymentPill("transfer", Icons.account_balance_rounded, "Transfer"),
              const SizedBox(width: 8),
              _buildPaymentPill("qris", Icons.qr_code_2_rounded, "QRIS"),
            ],
          ),
          const SizedBox(height: 28),

          // Subtotal, Discount, Total Calculation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(currencyFormat.format(_calculateSubtotal()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Diskon", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("- " + currencyFormat.format(int.tryParse(_discountController.text) ?? 0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Akhir", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(currencyFormat.format(_calculateTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("Konfirmasi Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(String method, IconData icon, String label) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5E3C) : Colors.white,
            border: Border.all(color: isSelected ? const Color(0xFF8B5E3C) : Colors.grey.shade300, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF8B5E3C), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 3: SUCCESS ANIMATION & CARD ---
  Widget _buildStep3Success() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Animated Checkmark
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Transaksi Berhasil Dicatat!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "Nomor Transaksi: $_successInvoice",
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 36),

            // Navigation CTA options
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Reset all
                        _selectedQuantities.clear();
                        _customerNameController.clear();
                        _discountController.text = "0";
                        _notesController.clear();
                        _paymentMethod = "cash";
                        _currentStep = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5E6D3),
                      foregroundColor: const Color(0xFF8B5E3C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Transaksi Baru", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Lihat Riwayat", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
