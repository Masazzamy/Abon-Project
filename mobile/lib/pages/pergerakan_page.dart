import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';

class PergerakanPage extends StatefulWidget {
  const PergerakanPage({super.key});

  @override
  State<PergerakanPage> createState() => _PergerakanPageState();
}

class _PergerakanPageState extends State<PergerakanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // API State
  bool _isLoading = false;
  List<Map<String, dynamic>> _movementsList = [];
  List<Map<String, dynamic>> _productList = [];

  // Filter States
  String _searchQuery = "";
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _sortBy = "Terbaru"; // Terbaru | Terlama | Terbanyak | Tersedikit

  // Colors
  static const Color colorPrimary = Color(0xFF8B5E3C);
  static const Color colorSecondary = Color(0xFFF5E6D3);
  static const Color colorAccent = Color(0xFFD4A853);
  static const Color colorBackground = Colors.white;
  static const Color colorSuccess = Color(0xFF4CAF50);
  static const Color colorAlert = Color(0xFFE53935);
  static const Color colorWarning = Color(0xFFFF9800);
  static const Color colorBlue = Colors.blue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Redraw badges on tab switch
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchMovements(),
      _fetchProducts(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchMovements() async {
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/stock-movements'), headers: headers);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success']) {
          setState(() {
            _movementsList = List<Map<String, dynamic>>.from(resBody['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching movements: $e");
    }
  }

  Future<void> _fetchProducts() async {
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
    }
  }

  Future<void> _deleteMovement(String id) async {
    try {
      final baseUrl = await AuthService.getBaseUrl();
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/stock-movements/$id'), headers: headers);

      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200 && resBody['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Catatan pergerakan stok berhasil dihapus"),
            backgroundColor: colorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? "Gagal menghapus pergerakan"),
            backgroundColor: colorAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchMovements(); // refresh to reset swipe
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi gagal: $e"),
          backgroundColor: colorAlert,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchMovements();
    }
  }

  // --- STATS HELPER METHODS ---
  int _getInboundToday() {
    final now = DateTime.now();
    return _movementsList.where((m) {
      final date = DateTime.parse(m['created_at']);
      return date.day == now.day && date.month == now.month && date.year == now.year && m['type'] == 'in' && !(m['reason'] ?? "").toString().toLowerCase().contains('retur');
    }).fold(0, (sum, m) => sum + (m['quantity'] as int));
  }

  int _getOutboundToday() {
    final now = DateTime.now();
    return _movementsList.where((m) {
      final date = DateTime.parse(m['created_at']);
      return date.day == now.day && date.month == now.month && date.year == now.year && m['type'] == 'out';
    }).fold(0, (sum, m) => sum + (m['quantity'] as int).abs());
  }

  int _getAdjustmentsToday() {
    final now = DateTime.now();
    return _movementsList.where((m) {
      final date = DateTime.parse(m['created_at']);
      return date.day == now.day && date.month == now.month && date.year == now.year && m['type'] == 'adjustment';
    }).length;
  }

  int _getReturnsToday() {
    final now = DateTime.now();
    return _movementsList.where((m) {
      final date = DateTime.parse(m['created_at']);
      final isRetur = (m['reason'] ?? "").toString().toLowerCase().contains('retur') || (m['reason'] ?? "").toString().toLowerCase().contains('return');
      return date.day == now.day && date.month == now.month && date.year == now.year && isRetur;
    }).fold(0, (sum, m) => sum + (m['quantity'] as int));
  }

  // Stock total in Gudang
  int _getTotalStockInWarehouse() {
    return _productList.fold(0, (sum, p) => sum + (p['stock'] as int));
  }

  // Filtered List Helper for tabs
  List<Map<String, dynamic>> _getFilteredList(String tabType) {
    List<Map<String, dynamic>> filtered = _movementsList.where((m) {
      // 1. Tab type filter
      if (tabType == "in") {
        if (m['type'] != 'in' || (m['reason'] ?? "").toString().toLowerCase().contains('retur')) return false;
      } else if (tabType == "out") {
        if (m['type'] != 'out') return false;
      } else if (tabType == "adjustment") {
        if (m['type'] != 'adjustment') return false;
      } else if (tabType == "retur") {
        final isRetur = (m['reason'] ?? "").toString().toLowerCase().contains('retur') || (m['reason'] ?? "").toString().toLowerCase().contains('return');
        if (!isRetur) return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final pName = m['product'] != null ? m['product']['name'].toString().toLowerCase() : "";
        final desc = (m['reason'] ?? "").toString().toLowerCase();
        if (!pName.contains(_searchQuery.toLowerCase()) && !desc.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // 3. Date range filter
      final date = DateTime.parse(m['created_at']);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      if (date.isBefore(start) || date.isAfter(end)) return false;

      return true;
    }).toList();

    // Sorting
    if (_sortBy == "Terbaru") {
      filtered.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
    } else if (_sortBy == "Terlama") {
      filtered.sort((a, b) => a['created_at'].toString().compareTo(b['created_at'].toString()));
    } else if (_sortBy == "Terbanyak") {
      filtered.sort((a, b) => (b['quantity'] as int).abs().compareTo((a['quantity'] as int).abs()));
    } else if (_sortBy == "Tersedikit") {
      filtered.sort((a, b) => (a['quantity'] as int).abs().compareTo((b['quantity'] as int).abs()));
    }

    return filtered;
  }

  // --- INTERACTION HANDLERS ---
  void _openNewMovementSheet({String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NewMovementSheet(
          productList: _productList,
          initialType: initialType,
          onSuccess: () => _loadData(),
        );
      },
    );
  }

  void _openDetailSheet(Map<String, dynamic> movement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MovementDetailSheet(
          movement: movement,
          onDelete: (id) => _deleteMovement(id),
        );
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: colorPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLowStock = _productList.any((p) => (p['stock'] as int) <= (p['min_stock'] as int));
    final hasOutOfStock = _productList.any((p) => (p['stock'] as int) <= 0);

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
                                  "Pergerakan Stok",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Pantau keluar masuk stok Anda",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // + Catat Pergerakan Button
                            ElevatedButton.icon(
                              onPressed: () => _openNewMovementSheet(),
                              icon: const Icon(
                                Icons.swap_vert_rounded,
                                size: 16,
                                color: colorPrimary,
                              ),
                              label: const Text(
                                "Catat Pergerakan",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          ];
        },
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2. SUMMARY STRIP & STOCK HEALTH BANNER (Scrollable widgets)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: colorPrimary,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 16),
                      // 2. SUMMARY STRIP
                      _SummaryStrip(
                        inToday: _getInboundToday(),
                        outToday: _getOutboundToday(),
                        adjToday: _getAdjustmentsToday(),
                        retToday: _getReturnsToday(),
                      ),
                      const SizedBox(height: 12),

                      // 3. STOCK HEALTH INDICATOR
                      _StockHealthIndicator(
                        hasLowStock: hasLowStock,
                        hasOutOfStock: hasOutOfStock,
                        lowStockCount: _productList.where((p) => (p['stock'] as int) <= (p['min_stock'] as int) && (p['stock'] as int) > 0).length,
                        outOfStockCount: _productList.where((p) => (p['stock'] as int) <= 0).length,
                      ),
                      const SizedBox(height: 16),

                      // 4. FLOW VISUALIZATION
                      _FlowVisualization(
                        inToday: _getInboundToday(),
                        outToday: _getOutboundToday(),
                        totalStock: _getTotalStockInWarehouse(),
                      ),
                      const SizedBox(height: 16),

                      // 5. QUICK ACTIONS BUTTONS
                      _buildQuickActionButtons(),
                      const SizedBox(height: 20),

                      // 6. MINI STOCK TIMELINE
                      _StockTimeline(movementsList: _movementsList),
                      const SizedBox(height: 24),

                      // 7. STICKY FILTER AND LIST (Embedded List View header inside scroll)
                      _buildMovementListSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openNewMovementSheet(initialType: 'in'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: colorSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorSuccess.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_box_outlined, color: colorSuccess, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Terima Stok",
                      style: TextStyle(color: colorSuccess, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openNewMovementSheet(initialType: 'adjustment'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: colorSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorPrimary.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: colorPrimary, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Stock Opname",
                      style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementListSection() {
    return Container(
      color: colorBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // STICKY TAB BAR
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: colorPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorAccent,
              indicatorWeight: 3.0,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                _buildTabBadge("Semua", _getFilteredList("all").length),
                _buildTabBadge("Masuk", _getFilteredList("in").length, colorSuccess),
                _buildTabBadge("Keluar", _getFilteredList("out").length, colorAlert),
                _buildTabBadge("Koreksi", _getFilteredList("adjustment").length, colorWarning),
              ],
            ),
          ),

          // FILTER & SEARCH BAR
          _FilterSearchBar(
            searchQuery: _searchQuery,
            startDate: _startDate,
            endDate: _endDate,
            sortBy: _sortBy,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            onDatePressed: () => _selectDateRange(),
            onSortChanged: (val) {
              setState(() {
                _sortBy = val!;
              });
            },
          ),

          // TAB CONTENT BUILDER
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: _buildActiveTabList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(String title, int count, [Color? color]) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color != null ? color.withOpacity(0.12) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabList() {
    String tabType = "all";
    if (_tabController.index == 1) tabType = "in";
    if (_tabController.index == 2) tabType = "out";
    if (_tabController.index == 3) tabType = "adjustment";

    final list = _getFilteredList(tabType);

    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (list.isEmpty) {
      return _buildEmptyState(tabType);
    }

    // Group movements by date
    Map<String, List<Map<String, dynamic>>> groupedMovements = {};
    for (var move in list) {
      final dateStr = _formatGroupDate(move['created_at']);
      if (!groupedMovements.containsKey(dateStr)) {
        groupedMovements[dateStr] = [];
      }
      groupedMovements[dateStr]!.add(move);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedMovements.keys.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = groupedMovements.keys.elementAt(dateIndex);
        final dayList = groupedMovements[dateKey]!;

        int totalIn = dayList.where((m) => m['type'] == 'in').fold(0, (sum, m) => sum + (m['quantity'] as int));
        int totalOut = dayList.where((m) => m['type'] == 'out').fold(0, (sum, m) => sum + (m['quantity'] as int).abs());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateGroupHeader(
              dateLabel: dateKey,
              totalIn: totalIn,
              totalOut: totalOut,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayList.length,
              itemBuilder: (context, index) {
                final movement = dayList[index];
                return _MovementCard(
                  movement: movement,
                  onTap: () => _openDetailSheet(movement),
                  onDismissed: () => _deleteMovement(movement['id'].toString()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatGroupDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Colors.white),
                const SizedBox(width: 12),
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
                Container(height: 12, width: 40, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String tabType) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    bool showButton = false;

    if (tabType == "in") {
      icon = Icons.arrow_circle_down_outlined;
      color = colorSuccess;
      title = "Belum Ada Stok Masuk";
      subtitle = "Catat penerimaan produk atau hasil produksi di sini";
    } else if (tabType == "out") {
      icon = Icons.arrow_circle_up_outlined;
      color = colorAlert;
      title = "Belum Ada Stok Keluar";
      subtitle = "Stok keluar tercatat otomatis saat ada penjualan";
    } else if (tabType == "adjustment") {
      icon = Icons.edit_note_outlined;
      color = colorWarning;
      title = "Belum Ada Koreksi Stok";
      subtitle = "Gunakan koreksi untuk menyesuaikan stok secara manual";
    } else {
      icon = Icons.swap_vert_outlined;
      color = colorPrimary;
      title = "Belum Ada Pergerakan Stok";
      subtitle = "Semua keluar masuk stok akan tercatat otomatis di sini";
      showButton = true;
    }

    return _EmptyState(
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      buttonText: showButton ? "+ Catat Pergerakan" : null,
      onButtonPressed: () => _openNewMovementSheet(),
    );
  }
}

// ==========================================
// WIDGET 1: HEADER SECTION
// (Using standard SliverAppBar embedded in page, so skipped separate file extraction)

// ==========================================
// WIDGET 2: SUMMARY STRIP
// ==========================================
class _SummaryStrip extends StatelessWidget {
  final int inToday;
  final int outToday;
  final int adjToday;
  final int retToday;

  const _SummaryStrip({
    required this.inToday,
    required this.outToday,
    required this.adjToday,
    required this.retToday,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildCard("Masuk Hari Ini", Icons.arrow_downward_rounded, const Color(0xFF4CAF50), "$inToday", "item masuk"),
          _buildCard("Keluar Hari Ini", Icons.arrow_upward_rounded, const Color(0xFFE53935), "$outToday", "item keluar"),
          _buildCard("Penyesuaian", Icons.tune_rounded, const Color(0xFFFF9800), "$adjToday", "koreksi stok"),
          _buildCard("Retur", Icons.keyboard_return_rounded, Colors.blue, "$retToday", "produk retur"),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color, String value, String label) {
    return Container(
      width: 130,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              CircleAvatar(
                radius: 10,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 10, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 3: STOCK HEALTH INDICATOR
// ==========================================
class _StockHealthIndicator extends StatelessWidget {
  final bool hasLowStock;
  final bool hasOutOfStock;
  final int lowStockCount;
  final int outOfStockCount;

  const _StockHealthIndicator({
    required this.hasLowStock,
    required this.hasOutOfStock,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String message;

    if (hasOutOfStock) {
      bg = const Color(0xFFE53935).withOpacity(0.08);
      border = const Color(0xFFE53935).withOpacity(0.2);
      textColor = const Color(0xFFE53935);
      icon = Icons.cancel;
      message = "$outOfStockCount produk stok habis!";
    } else if (hasLowStock) {
      bg = const Color(0xFFFF9800).withOpacity(0.08);
      border = const Color(0xFFFF9800).withOpacity(0.2);
      textColor = const Color(0xFFFF9800);
      icon = Icons.warning_rounded;
      message = "$lowStockCount produk perlu diperhatikan (stok menipis)";
    } else {
      bg = const Color(0xFF4CAF50).withOpacity(0.08);
      border = const Color(0xFF4CAF50).withOpacity(0.2);
      textColor = const Color(0xFF4CAF50);
      icon = Icons.check_circle;
      message = "Semua stok dalam kondisi baik";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 4: FLOW VISUALIZATION
// ==========================================
class _FlowVisualization extends StatefulWidget {
  final int inToday;
  final int outToday;
  final int totalStock;

  const _FlowVisualization({
    required this.inToday,
    required this.outToday,
    required this.totalStock,
  });

  @override
  State<_FlowVisualization> createState() => _FlowVisualizationState();
}

class _FlowVisualizationState extends State<_FlowVisualization> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = widget.inToday == 0 && widget.outToday == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Alur Stok Hari Ini",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),

          // Horizontal Diagram Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. MASUK BOX
              _buildBox(
                title: "MASUK",
                value: "+${widget.inToday} item",
                icon: Icons.login_rounded,
                borderColor: const Color(0xFF4CAF50),
              ),

              // Animated Connector In
              Expanded(
                child: _AnimatedArrow(controller: _controller, color: const Color(0xFF4CAF50)),
              ),

              // 2. GUDANG BOX
              _buildBox(
                title: "GUDANG",
                value: "Stok Total: ${widget.totalStock}",
                icon: Icons.warehouse_rounded,
                bgColor: const Color(0xFFF5E6D3),
                textColor: const Color(0xFF8B5E3C),
              ),

              // Animated Connector Out
              Expanded(
                child: _AnimatedArrow(controller: _controller, color: const Color(0xFFE53935)),
              ),

              // 3. KELUAR BOX
              _buildBox(
                title: "KELUAR",
                value: "-${widget.outToday} item",
                icon: Icons.logout_rounded,
                borderColor: const Color(0xFFE53935),
              ),
            ],
          ),
          if (isEmpty) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Belum ada pergerakan hari ini",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBox({
    required String title,
    required String value,
    required IconData icon,
    Color? borderColor,
    Color? bgColor,
    Color? textColor,
  }) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor ?? borderColor ?? Colors.black54, size: 18),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor ?? borderColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _AnimatedArrow extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _AnimatedArrow({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 10),
          painter: _ArrowPainter(progress: controller.value, color: color),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArrowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw base line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Draw animated moving dots
    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final double x = size.width * progress;
    canvas.drawCircle(Offset(x, size.height / 2), 2, dotPaint);

    // If dot gets close to the end, wrap around
    final double x2 = size.width * ((progress + 0.5) % 1.0);
    canvas.drawCircle(Offset(x2, size.height / 2), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// WIDGET 5: FILTER & SEARCH BAR
// ==========================================
class _FilterSearchBar extends StatelessWidget {
  final String searchQuery;
  final DateTime startDate;
  final DateTime endDate;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onDatePressed;
  final ValueChanged<String?> onSortChanged;

  const _FilterSearchBar({
    required this.searchQuery,
    required this.startDate,
    required this.endDate,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onDatePressed,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String dateLabel = "${DateFormat('d MMM', 'id_ID').format(startDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(endDate)}";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Cari produk...",
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    fillColor: Color(0xFFF9F9F9),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),

              // Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortBy,
                    icon: const Icon(Icons.sort_rounded, color: Color(0xFF8B5E3C), size: 20),
                    items: ["Terbaru", "Terlama", "Terbanyak", "Tersedikit"]
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    onChanged: onSortChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date Picker Shortcut button
          InkWell(
            onTap: onDatePressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF8B5E3C)),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 6: DATE GROUP HEADER
// ==========================================
class _DateGroupHeader extends StatelessWidget {
  final String dateLabel;
  final int totalIn;
  final int totalOut;

  const _DateGroupHeader({
    required this.dateLabel,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5E6D3).withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
          ),
          Row(
            children: [
              Text(
                "+$totalIn",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 6),
              const Text("|", style: TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(width: 6),
              Text(
                "-$totalOut",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 7: MOVEMENT CARD
// ==========================================
class _MovementCard extends StatelessWidget {
  final Map<String, dynamic> movement;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _MovementCard({
    required this.movement,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final String pName = movement['product'] != null ? movement['product']['name'] : "Produk #${movement['product_id']}";
    final int qty = movement['quantity'] as int;
    final String reason = movement['reason'] ?? "-";
    final String timeStr = DateFormat('HH:mm').format(DateTime.parse(movement['created_at']));
    final String logger = movement['user'] != null ? movement['user']['name'] : "Masazzamy";
    final String type = movement['type'];
    final bool isRetur = reason.toLowerCase().contains('retur') || reason.toLowerCase().contains('return');

    // Theme values
    Color accentColor;
    String typeLabel;
    IconData icon;
    String amountStr;

    if (isRetur) {
      accentColor = Colors.blue;
      typeLabel = "RETUR";
      icon = Icons.keyboard_return_rounded;
      amountStr = "+$qty pcs";
    } else if (type == 'in') {
      accentColor = const Color(0xFF4CAF50);
      typeLabel = "MASUK";
      icon = Icons.arrow_downward_rounded;
      amountStr = "+$qty pcs";
    } else if (type == 'out') {
      accentColor = const Color(0xFFE53935);
      typeLabel = "KELUAR";
      icon = Icons.arrow_upward_rounded;
      amountStr = "-${qty.abs()} pcs";
    } else {
      accentColor = const Color(0xFFFF9800);
      typeLabel = "KOREKSI";
      icon = Icons.tune_rounded;
      amountStr = qty >= 0 ? "+$qty pcs" : "$qty pcs";
    }

    return Dismissible(
      key: Key("movement_${movement['id']}"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hapus Catatan"),
            content: const Text("Apakah Anda yakin ingin menghapus catatan pergerakan ini? Stok produk akan dikembalikan."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Tutup")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Color(0xFFE53935)))),
            ],
          ),
        );
      },
      onDismissed: (dir) => onDismissed(),
      background: Container(
        color: const Color(0xFFE53935),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              // 1. LEFT BAR
              Container(width: 4, height: 68, color: accentColor),
              const SizedBox(width: 14),

              // 2. ICON
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withOpacity(0.12),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 12),

              // 3. CONTENT AREA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$reason • $timeStr WIB • oleh $logger",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. AMOUNT
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                  amountStr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET 8: MOVEMENT DETAIL BOTTOM SHEET
// ==========================================
class _MovementDetailSheet extends StatelessWidget {
  final Map<String, dynamic> movement;
  final ValueChanged<String> onDelete;

  const _MovementDetailSheet({
    required this.movement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String id = movement['id'].toString();
    final String pName = movement['product'] != null ? movement['product']['name'] : "Produk #${movement['product_id']}";
    final int qty = movement['quantity'] as int;
    final String reason = movement['reason'] ?? "-";
    final String timeStr = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(movement['created_at']));
    final String logger = movement['user'] != null ? movement['user']['name'] : "Masazzamy";
    final String type = movement['type'];
    final bool isRetur = reason.toLowerCase().contains('retur') || reason.toLowerCase().contains('return');

    Color accentColor;
    String typeLabel;
    IconData icon;
    String amountStr;

    if (isRetur) {
      accentColor = Colors.blue;
      typeLabel = "RETUR";
      icon = Icons.keyboard_return_rounded;
      amountStr = "+$qty pcs";
    } else if (type == 'in') {
      accentColor = const Color(0xFF4CAF50);
      typeLabel = "MASUK";
      icon = Icons.arrow_downward_rounded;
      amountStr = "+$qty pcs";
    } else if (type == 'out') {
      accentColor = const Color(0xFFE53935);
      typeLabel = "KELUAR";
      icon = Icons.arrow_upward_rounded;
      amountStr = "-${qty.abs()} pcs";
    } else {
      accentColor = const Color(0xFFFF9800);
      typeLabel = "KOREKSI";
      icon = Icons.tune_rounded;
      amountStr = qty >= 0 ? "+$qty pcs" : "$qty pcs";
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 20),

          // Header Colored Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, size: 40, color: accentColor),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rows
          _buildInfoRow("Produk", pName, true),
          _buildInfoRow("Jumlah", amountStr, false, accentColor),
          _buildInfoRow("Tanggal/Waktu", "$timeStr WIB", false),
          _buildInfoRow("Keterangan", reason, false),
          _buildInfoRow("Dicatat Oleh", logger, false),
          _buildInfoRow("ID Pergerakan", "#MVT-0$id", false, Colors.grey),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete(id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Hapus Catatan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool boldValue, [Color? textColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 9: NEW MOVEMENT CREATION SHEET (3-STEP)
// ==========================================
class _NewMovementSheet extends StatefulWidget {
  final List<Map<String, dynamic>> productList;
  final String? initialType;
  final VoidCallback onSuccess;

  const _NewMovementSheet({
    required this.productList,
    this.initialType,
    required this.onSuccess,
  });

  @override
  State<_NewMovementSheet> createState() => _NewMovementSheetState();
}

class _NewMovementSheetState extends State<_NewMovementSheet> with SingleTickerProviderStateMixin {
  int _currentStep = 1;
  String _selectedType = "in"; // in | out | adjustment | retur

  // Step 2 variables
  int? _selectedProductId;
  int _quantity = 1;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _currentStep = 2; // Jump straight to step 2 if type is preselected
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getDefaultPlaceholderReason() {
    if (_selectedType == 'in') return "Produksi batch #001";
    if (_selectedType == 'out') return "Penjualan offline";
    if (_selectedType == 'adjustment') return "Hasil stock opname";
    return "Produk rusak/dikembalikan pembeli";
  }

  Future<void> _submitMovement() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih produk terlebih dahulu")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baseUrl = await AuthService.getBaseUrl();
      final token = await AuthService().getToken();

      // Normalize fields depending on 'retur' mapping
      String typePayload = _selectedType;
      String reasonPayload = _reasonController.text.trim().isEmpty ? _getDefaultPlaceholderReason() : _reasonController.text.trim();
      int quantityPayload = _quantity;

      if (_selectedType == 'retur') {
        typePayload = 'in'; // Retur is saved as inbound stock
        reasonPayload = "Retur: $reasonPayload";
      }

      // Negative quantity check for outbound
      if (typePayload == 'out') {
        quantityPayload = quantityPayload.abs(); // Store as absolute positive in Laravel controller adjusts
      }

      final response = await http.post(
        Uri.parse('$baseUrl/stock-movements'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': _selectedProductId,
          'type': typePayload,
          'quantity': quantityPayload,
          'reason': reasonPayload,
        }),
      );

      final resBody = jsonDecode(response.body);

      if (response.statusCode == 201 && resBody['success']) {
        setState(() {
          _currentStep = 3; // Success confirmation
        });
        _animationController.forward(from: 0.0);
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? "Gagal mencatat pergerakan"),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),

              // Steps Header Title
              if (_currentStep == 1) ...[
                const Text("Pilih Tipe Pergerakan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
                const SizedBox(height: 2),
                const Text("Tentukan jenis perubahan stok yang terjadi", style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    const Text("Form Detail Pergerakan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
                  ],
                ),
              ],
              const Divider(height: 18),

              Expanded(
                child: _buildStepBody(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepBody(ScrollController scrollController) {
    if (_currentStep == 1) {
      return _buildStep1TypeGrid();
    } else if (_currentStep == 2) {
      return _buildStep2DetailsForm(scrollController);
    } else {
      return _buildStep3Success();
    }
  }

  // --- STEP 1 ---
  Widget _buildStep1TypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildTypeTile("in", Icons.arrow_downward_rounded, const Color(0xFF4CAF50), "Stok Masuk", "Terima produk atau produksi baru"),
        _buildTypeTile("out", Icons.arrow_upward_rounded, const Color(0xFFE53935), "Stok Keluar", "Produk dijual atau terpakai"),
        _buildTypeTile("adjustment", Icons.tune_rounded, const Color(0xFFFF9800), "Penyesuaian", "Koreksi nilai stok secara manual"),
        _buildTypeTile("retur", Icons.keyboard_return_rounded, Colors.blue, "Retur", "Produk dikembalikan pembeli"),
      ],
    );
  }

  Widget _buildTypeTile(String type, IconData icon, Color color, String title, String subtitle) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _currentStep = 2;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- STEP 2 ---
  Widget _buildStep2DetailsForm(ScrollController scrollController) {
    final activeProduct = widget.productList.firstWhere(
      (p) => p['id'] == _selectedProductId,
      orElse: () => <String, dynamic>{},
    );

    final int currentStock = activeProduct['stock'] ?? 0;
    int resultingStock = currentStock;

    if (_selectedType == 'in' || _selectedType == 'retur') {
      resultingStock = currentStock + _quantity;
    } else if (_selectedType == 'out') {
      resultingStock = currentStock - _quantity;
    } else if (_selectedType == 'adjustment') {
      resultingStock = currentStock + _quantity; // handles +/- corrections
    }

    final isNegativeResult = resultingStock < 0;

    return ListView(
      controller: scrollController,
      children: [
        // Dropdown Product Selection
        const Text("Pilih Produk", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedProductId,
              hint: const Text("Pilih produk dari katalog...", style: TextStyle(fontSize: 13)),
              items: widget.productList.map((p) {
                return DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(
                    "${p['name']} (Stok: ${p['stock']} ${p['unit'] ?? 'pcs'})",
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProductId = val;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Stepper Quantity Input
        const Text("Jumlah Unit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B5E3C), size: 30),
              onPressed: () {
                setState(() {
                  if (_quantity > 1) {
                    _quantity--;
                  } else if (_selectedType == 'adjustment') {
                    _quantity--; // allows negative inputs for adjustments
                  }
                });
              },
            ),
            const SizedBox(width: 20),
            Text(
              "$_quantity",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B5E3C), size: 30),
              onPressed: () {
                setState(() {
                  _quantity++;
                });
              },
            ),
          ],
        ),
        if (_selectedType == 'adjustment') ...[
          const SizedBox(height: 6),
          const Center(
            child: Text(
              "Gunakan nilai negatif jika ingin mengurangi stok",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Text input reason
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: "Keterangan",
            hintText: "Contoh: ${_getDefaultPlaceholderReason()}",
            prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF8B5E3C)),
          ),
        ),
        const SizedBox(height: 24),

        // Preview Card
        if (_selectedProductId != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNegativeResult ? const Color(0xFFE53935).withOpacity(0.08) : const Color(0xFF8B5E3C).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNegativeResult ? const Color(0xFFE53935).withOpacity(0.2) : const Color(0xFF8B5E3C).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ringkasan Perubahan", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  "${activeProduct['name']} akan ${_selectedType == 'out' ? 'berkurang' : 'bertambah'} sebanyak ${_quantity.abs()} unit.",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  "Stok: $currentStock → $resultingStock",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isNegativeResult ? const Color(0xFFE53935) : const Color(0xFF8B5E3C)),
                ),
                if (isNegativeResult) ...[
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 14),
                      SizedBox(width: 6),
                      Text("Peringatan: Stok akan menjadi minus!", style: TextStyle(fontSize: 10, color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Submit Button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitMovement,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5E3C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Simpan Pergerakan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // --- STEP 3 ---
  Widget _buildStep3Success() {
    String message = "Stok Berhasil Ditambahkan! 📦";
    if (_selectedType == 'out') message = "Stok Keluar Tercatat! ✅";
    if (_selectedType == 'adjustment') message = "Stok Berhasil Disesuaikan! 🔧";
    if (_selectedType == 'retur') message = "Retur Berhasil Dicatat! 🔄";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
            ),
          ),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Kembali ke Halaman", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 10: MINI STOCK TIMELINE
// ==========================================
class _StockTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> movementsList;

  const _StockTimeline({required this.movementsList});

  @override
  Widget build(BuildContext context) {
    // Generate mock date list for last 7 days
    final now = DateTime.now();
    final dates = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    // Calculate in/out for each of the last 7 days
    List<double> inData = [];
    List<double> outData = [];

    for (var date in dates) {
      double dayIn = 0;
      double dayOut = 0;

      for (var m in movementsList) {
        final mDate = DateTime.parse(m['created_at']);
        if (mDate.day == date.day && mDate.month == date.month && mDate.year == date.year) {
          final int qty = m['quantity'] as int;
          if (m['type'] == 'in') {
            dayIn += qty;
          } else if (m['type'] == 'out') {
            dayOut += qty.abs();
          }
        }
      }
      inData.add(dayIn);
      outData.add(dayOut);
    }

    final double maxVal = 10.0; // scale minimum default

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Timeline Stok (7 Hari Terakhir)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final daysStr = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];
                        final dayIndex = dates[val.toInt() % 7].weekday % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(daysStr[dayIndex], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: inData[index], color: const Color(0xFF4CAF50), width: 6),
                      BarChartRodData(toY: outData[index], color: const Color(0xFFE53935), width: 6),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              const Text("Masuk", style: TextStyle(fontSize: 9, color: Colors.grey)),
              const SizedBox(width: 16),
              Container(width: 8, height: 8, color: const Color(0xFFE53935)),
              const SizedBox(width: 6),
              const Text("Keluar", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET 11: REUSABLE EMPTY STATE WIDGET
// ==========================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(buttonText!, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
