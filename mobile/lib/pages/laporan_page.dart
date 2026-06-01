import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // API State
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  // Filter Period
  String _selectedPeriod = "Bulan"; // Hari | Minggu | Bulan | Custom
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Float button scroll controller
  late ScrollController _scrollController;
  bool _showFloatingPeriod = true;

  // Color constants
  static const Color colorPrimary = Color(0xFF8B5E3C);
  static const Color colorSecondary = Color(0xFFF5E6D3);
  static const Color colorAccent = Color(0xFFD4A853);
  static const Color colorBackground = Colors.white;
  static const Color colorSuccess = Color(0xFF4CAF50);
  static const Color colorAlert = Color(0xFFE53935);
  static const Color colorWarning = Color(0xFFFF9800);
  static const Color colorInfo = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 100 && _showFloatingPeriod) {
        setState(() => _showFloatingPeriod = false);
      } else if (_scrollController.position.pixels <= 100 && !_showFloatingPeriod) {
        setState(() => _showFloatingPeriod = true);
      }
    });

    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      final baseUrl = await AuthService.getBaseUrl();
      final token = await _authService.getToken();

      String periodPayload = "month";
      if (_selectedPeriod == "Hari") periodPayload = "day";
      if (_selectedPeriod == "Minggu") periodPayload = "week";
      if (_selectedPeriod == "Bulan") periodPayload = "month";
      if (_selectedPeriod == "Custom") periodPayload = "custom";

      String url = '$baseUrl/reports/summary?period=$periodPayload';
      if (_selectedPeriod == "Custom") {
        url += '&start_date=${DateFormat('Y-MM-dd').format(_startDate)}&end_date=${DateFormat('Y-MM-dd').format(_endDate)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        if (resBody['success']) {
          setState(() {
            _reportData = resBody['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePeriod(String period) async {
    if (period == "Custom") {
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
          _selectedPeriod = period;
          _startDate = picked.start;
          _endDate = picked.end;
        });
        _loadReportData();
      }
    } else {
      setState(() {
        _selectedPeriod = period;
      });
      _loadReportData();
    }
  }

  void _shiftPeriod(bool forward) {
    if (_selectedPeriod == "Hari") {
      setState(() {
        final delta = forward ? 1 : -1;
        _startDate = _startDate.add(Duration(days: delta));
        _endDate = _startDate;
      });
    } else if (_selectedPeriod == "Minggu") {
      setState(() {
        final delta = forward ? 7 : -7;
        _startDate = _startDate.add(Duration(days: delta));
        _endDate = _endDate.add(Duration(days: delta));
      });
    } else if (_selectedPeriod == "Bulan") {
      setState(() {
        final delta = forward ? 1 : -1;
        _startDate = DateTime(_startDate.year, _startDate.month + delta, 1);
        _endDate = DateTime(_endDate.year, _endDate.month + delta + 1, 0);
      });
    }
    _loadReportData();
  }

  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ExportBottomSheet(),
    );
  }

  String _getPeriodLabel() {
    if (_selectedPeriod == "Hari") {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_startDate);
    } else if (_selectedPeriod == "Bulan") {
      return DateFormat('MMMM yyyy', 'id_ID').format(_startDate);
    } else {
      return "${DateFormat('d MMM', 'id_ID').format(_startDate)} - ${DateFormat('d MMM yyyy', 'id_ID').format(_endDate)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      floatingActionButton: _showFloatingPeriod
          ? FloatingActionButton.extended(
              onPressed: () => _changePeriod(_selectedPeriod == "Bulan" ? "Custom" : "Bulan"),
              backgroundColor: colorPrimary,
              icon: const Icon(Icons.date_range_rounded, color: Colors.white, size: 16),
              label: Text(
                _getPeriodLabel(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. HEADER SECTION
            SliverAppBar(
              expandedHeight: 150.0,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Laporan Bisnis",
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Analisis mendalam usaha Anda",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        // Export Button
                        IconButton(
                          onPressed: _openExportSheet,
                          icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 24),
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
              // 2. PERIOD SELECTOR BAR
              _PeriodSelectorBar(
                selectedPeriod: _selectedPeriod,
                periodLabel: _getPeriodLabel(),
                onPeriodSelected: _changePeriod,
                onShiftPressed: _shiftPeriod,
              ),

              // 3. TAB BAR (STICKY)
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorPrimary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: colorAccent,
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Keuangan 💰"),
                    Tab(text: "Penjualan 🛒"),
                    Tab(text: "Stok 📦"),
                    Tab(text: "Harian 📅"),
                  ],
                ),
              ),

              // TAB CONTENT
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadReportData,
                  color: colorPrimary,
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _KeuanganTab(reportData: _reportData),
                            _PenjualanTab(reportData: _reportData),
                            _StokTab(reportData: _reportData),
                            _HarianTab(reportData: _reportData),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              height: 140,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// WIDGET 2: PERIOD SELECTOR BAR
// ==========================================
class _PeriodSelectorBar extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final ValueChanged<String> onPeriodSelected;
  final ValueChanged<bool> onShiftPressed;

  const _PeriodSelectorBar({
    required this.selectedPeriod,
    required this.periodLabel,
    required this.onPeriodSelected,
    required this.onShiftPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["Hari", "Minggu", "Bulan", "Custom"].map((p) {
              final isActive = selectedPeriod == p;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => onPeriodSelected(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF8B5E3C) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B5E3C), width: 1.2),
                      ),
                      child: Text(
                        p,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : const Color(0xFF8B5E3C),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF8B5E3C)),
                onPressed: selectedPeriod == 'Custom' ? null : () => onShiftPressed(false),
              ),
              Text(
                periodLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B5E3C)),
                onPressed: selectedPeriod == 'Custom' ? null : () => onShiftPressed(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: INSIGHT CARD
// ==========================================
class _InsightCard extends StatefulWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFFD4A853), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Insight Bisnis",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.text,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            onPressed: () => setState(() => _visible = false),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: KEUANGAN
// ==========================================
class _KeuanganTab extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const _KeuanganTab({required this.reportData});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = reportData?['keuangan'] ?? {};

    final totalRev = data['total_revenue'] ?? 0;
    final totalCost = data['total_cost'] ?? 0;
    final netProfit = data['net_profit'] ?? 0;
    final margin = data['margin_percentage'] ?? 0;
    final txCount = data['total_transactions'] ?? 0;
    final dailyAvg = data['daily_average'] ?? 0;
    final List<dynamic> daysSeries = data['days_series'] ?? [];
    final List<dynamic> contributions = data['product_contributions'] ?? [];

    final isDataEmpty = totalRev == 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _InsightCard(
          text: isDataEmpty
              ? "Mulai catat transaksi untuk mendapatkan insight bisnis Anda."
              : "Laba bersih Anda berada di kisaran $margin%. Pertahankan penjualan harian rata-rata Anda!",
        ),

        // A. HERO PROFIT CARD
        _HeroProfitCard(
          revenue: totalRev,
          cost: totalCost,
          profit: netProfit,
          margin: margin,
        ),

        // B. FINANCIAL SUMMARY CARDS
        _FinancialSummaryCards(
          revenue: totalRev,
          cost: totalCost,
          transactions: txCount,
          dailyAvg: dailyAvg,
        ),

        // C. REVENUE vs COST CHART
        _buildRevenueCostChart(daysSeries, isDataEmpty),

        // D. BREAKDOWN KATEGORI (PRODUCT CONTRIBUTIONS)
        _buildContributionsDonut(contributions, totalRev, isDataEmpty),

        // E. CATATAN KEUANGAN
        _buildFinancialNotes(),
      ],
    );
  }

  Widget _buildRevenueCostChart(List<dynamic> series, bool isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pendapatan vs Modal", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || series.isEmpty)
            const _EmptyState(
              icon: Icons.bar_chart_rounded,
              iconColor: Colors.grey,
              title: "Belum ada data keuangan",
              subtitle: "Data grafik akan muncul setelah ada penjualan.",
            )
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < series.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(series[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(series.length, (idx) {
                    final double rev = (series[idx]['revenue'] as int).toDouble();
                    final double cost = (series[idx]['cost'] as int).toDouble();
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(toY: rev, color: const Color(0xFF8B5E3C), width: 6),
                        BarChartRodData(toY: cost, color: const Color(0xFFF5E6D3), width: 6),
                      ],
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop, color: Color(0xFF8B5E3C), size: 16),
              Text("Pendapatan", style: TextStyle(fontSize: 10, color: Colors.grey)),
              SizedBox(width: 16),
              Icon(Icons.stop, color: Color(0xFFF5E6D3), size: 16),
              Text("Modal", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsDonut(List<dynamic> contributions, int totalRev, bool isEmpty) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kontribusi Per Produk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || contributions.isEmpty)
            const _EmptyState(
              icon: Icons.pie_chart_rounded,
              iconColor: Colors.grey,
              title: "Belum ada data produk",
              subtitle: "Data produk akan terisi secara otomatis.",
            )
          else ...[
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: contributions.map((c) {
                    final double pct = (c['percentage'] as num).toDouble();
                    return PieChartSectionData(
                      color: Color(((0xFF8B5E3C + (c['product_id'] as int) * 123456).toInt()) | 0xFF000000),
                      value: pct,
                      title: "$pct%",
                      radius: 30,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contributions.length,
              itemBuilder: (context, idx) {
                final c = contributions[idx];
                final color = Color(((0xFF8B5E3C + (c['product_id'] as int) * 123456).toInt()) | 0xFF000000);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c['name'] ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        "${c['percentage']}% (${currencyFormatter.format(c['revenue'])})",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: const Color(0xFF8B5E3C), width: 4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF8B5E3C), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Data laba merupakan estimasi berdasarkan harga modal asumsi 60%. Untuk laporan pajak resmi, harap konsultasikan dengan akuntan profesional Anda.",
              style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: HERO PROFIT CARD
// ==========================================
class _HeroProfitCard extends StatelessWidget {
  final int revenue;
  final int cost;
  final int profit;
  final int margin;

  const _HeroProfitCard({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5E3C), Color(0xFFD4A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5E3C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Estimasi Laba Bersih",
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormatter.format(profit),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pendapatan: ${currencyFormatter.format(revenue)}",
                style: const TextStyle(color: Color(0xFFD4EAD4), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const Text("|", style: TextStyle(color: Colors.white30)),
              Text(
                "Modal: ${currencyFormatter.format(cost)}",
                style: const TextStyle(color: Color(0xFFFCDDDC), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Margin: $margin%", style: const TextStyle(color: Colors.white, fontSize: 10)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: margin / 100.0,
                      backgroundColor: Colors.white24,
                      color: const Color(0xFFD4A853),
                      minHeight: 4,
                    ),
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

// ==========================================
// WIDGET: FINANCIAL SUMMARY CARDS
// ==========================================
class _FinancialSummaryCards extends StatelessWidget {
  final int revenue;
  final int cost;
  final int transactions;
  final int dailyAvg;

  const _FinancialSummaryCards({
    required this.revenue,
    required this.cost,
    required this.transactions,
    required this.dailyAvg,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.45,
        children: [
          _buildCard("Total Pendapatan", currencyFormatter.format(revenue), "$transactions transaksi", Icons.trending_up, Colors.green),
          _buildCard("Total Modal", currencyFormatter.format(cost), "Harga pokok produksi", Icons.trending_down, Colors.red),
          _buildCard("Rata-rata/Hari", currencyFormatter.format(dailyAvg), "Per hari aktif", Icons.calendar_today, Colors.brown),
          _buildCard("Transaksi", "$transactions", "Total transaksi", Icons.receipt_rounded, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
              Icon(icon, size: 16, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
// TAB 2: PENJUALAN
// ==========================================
class _PenjualanTab extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const _PenjualanTab({required this.reportData});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = reportData?['penjualan'] ?? {};

    final int totalSold = data['total_items_sold'] ?? 0;
    final int distinctProd = data['distinct_products_count'] ?? 0;
    final List<dynamic> topProducts = data['top_products'] ?? [];
    final List<dynamic> hourly = data['hourly_sales'] ?? List.filled(24, 0);
    final Map<String, dynamic> payments = data['payment_methods'] ?? {};

    final isDataEmpty = totalSold == 0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // A. SALES PERFORMANCE BANNER
        _buildPerformanceBanner(totalSold, distinctProd),

        // B. TREN PENJUALAN CHART
        _buildSalesTrendChart(reportData?['keuangan']?['days_series'] ?? [], isDataEmpty),

        // C. TOP 5 PRODUK TERLARIS
        _TopProductsList(topProducts: topProducts, isEmpty: isDataEmpty),

        // D. PENJUALAN PER JAM (Heatmap style)
        _HourlyHeatmap(hourly: hourly),

        // E. METODE PEMBAYARAN
        _buildPaymentMethods(payments, isDataEmpty),
      ],
    );
  }

  Widget _buildPerformanceBanner(int totalSold, int distinctProd) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF8B5E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Terjual: $totalSold item",
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                "dari $distinctProd produk berbeda",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart(List<dynamic> series, bool isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tren Penjualan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || series.isEmpty)
            const _EmptyState(
              icon: Icons.show_chart_rounded,
              iconColor: Colors.grey,
              title: "Belum ada data penjualan",
              subtitle: "Tren penjualan akan muncul saat ada transaksi.",
            )
          else
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < series.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(series[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(series.length, (idx) {
                        final double rev = (series[idx]['revenue'] as int).toDouble();
                        return FlSpot(idx.toDouble(), rev);
                      }),
                      isCurved: true,
                      color: const Color(0xFFD4A853),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFD4A853).withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(Map<String, dynamic> payments, bool isEmpty) {
    final int tunai = payments['Tunai'] ?? 0;
    final int transfer = payments['Transfer'] ?? 0;
    final int qris = payments['QRIS'] ?? 0;
    final total = tunai + transfer + qris;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Metode Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || total == 0)
            const _EmptyState(
              icon: Icons.payment_rounded,
              iconColor: Colors.grey,
              title: "Belum ada transaksi pembayaran",
              subtitle: "Pembagian metode pembayaran tampil di sini.",
            )
          else ...[
            _buildPaymentMethodRow("Tunai", tunai, total, const Color(0xFF8B5E3C)),
            _buildPaymentMethodRow("Transfer", transfer, total, const Color(0xFFD4A853)),
            _buildPaymentMethodRow("QRIS", qris, total, const Color(0xFF4CAF50)),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(String label, int value, int total, Color color) {
    final double pct = total > 0 ? (value / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text("$value tx (${pct.toStringAsFixed(1)}%)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? value / total : 0,
              color: color,
              backgroundColor: Colors.grey.shade100,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: TOP 5 PRODUCTS LIST
// ==========================================
class _TopProductsList extends StatelessWidget {
  final List<dynamic> topProducts;
  final bool isEmpty;

  const _TopProductsList({required this.topProducts, required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Produk Terlaris", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (isEmpty || topProducts.isEmpty)
            const _EmptyState(
              icon: Icons.emoji_events_outlined,
              iconColor: Colors.grey,
              title: "Belum ada produk terlaris",
              subtitle: "Data rangking produk terlaris akan tampil di sini.",
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              itemBuilder: (context, idx) {
                final prod = topProducts[idx];
                final int sold = prod['sold_count'] ?? 0;
                final int rev = prod['revenue'] ?? 0;

                Widget rankBadge;
                if (idx == 0) {
                  rankBadge = const CircleAvatar(radius: 10, backgroundColor: Color(0xFFD4A853), child: Text("🥇", style: TextStyle(fontSize: 9)));
                } else if (idx == 1) {
                  rankBadge = const CircleAvatar(radius: 10, backgroundColor: Colors.grey, child: Text("🥈", style: TextStyle(fontSize: 9)));
                } else if (idx == 2) {
                  rankBadge = const CircleAvatar(radius: 10, backgroundColor: Colors.orange, child: Text("🥉", style: TextStyle(fontSize: 9)));
                } else {
                  rankBadge = CircleAvatar(radius: 10, backgroundColor: Colors.grey.shade200, child: Text("${idx + 1}", style: const TextStyle(fontSize: 8, color: Colors.grey)));
                }

                // Progress relative to Rank 1
                final double maxSold = (topProducts[0]['sold_count'] as int).toDouble();
                final double progress = maxSold > 0 ? sold / maxSold : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      rankBadge,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prod['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              "Terjual: $sold pcs  •  Revenue: ${currencyFormatter.format(rev)}",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                color: const Color(0xFF8B5E3C),
                                backgroundColor: Colors.grey.shade100,
                                minHeight: 4,
                              ),
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

// ==========================================
// WIDGET: HOURLY HEATMAP
// ==========================================
class _HourlyHeatmap extends StatelessWidget {
  final List<dynamic> hourly;

  const _HourlyHeatmap({required this.hourly});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Jam Penjualan Tersibuk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: List.generate(24, (index) {
              final val = index < hourly.length ? hourly[index] as int : 0;

              Color bg = Colors.grey.shade100;
              if (val > 10) {
                bg = const Color(0xFF5C3C24);
              } else if (val > 5) {
                bg = const Color(0xFF8B5E3C);
              } else if (val > 0) {
                bg = const Color(0xFFF5E6D3);
              }

              Color textCol = val > 5 ? Colors.white : Colors.black87;

              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Jam $index:00 - $val transaksi"),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Sepi", style: TextStyle(fontSize: 9, color: Colors.grey)),
              SizedBox(width: 4),
              Icon(Icons.stop, color: Color(0xFFF5E6D3), size: 14),
              Icon(Icons.stop, color: Color(0xFF8B5E3C), size: 14),
              Icon(Icons.stop, color: Color(0xFF5C3C24), size: 14),
              SizedBox(width: 4),
              Text("Sibuk", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: STOK (INVENTARIS)
// ==========================================
class _StokTab extends StatelessWidget {
  final Map<String, dynamic>? reportData;

  const _StokTab({required this.reportData});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = reportData?['stok'] ?? {};

    final valTotal = data['total_stock_value'] ?? 0;
    final int activeProd = data['active_products_count'] ?? 0;
    final int emptyProd = data['out_of_stock_count'] ?? 0;
    final Map<String, dynamic> statusCounts = data['stock_status'] ?? {};
    final List<dynamic> movements = data['stock_movements_7_days'] ?? [];
    final List<dynamic> table = data['product_stock_table'] ?? [];

    final isDataEmpty = table.isEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // A. STOCK VALUE CARD
        _buildStockValueCard(valTotal, activeProd, emptyProd),

        // B. STOCK STATUS CHART
        _buildStockStatusDonut(statusCounts, table.length, isDataEmpty),

        // C. PERGERAKAN STOK CHART (7 HARI)
        _buildStockMovementsChart(movements, isDataEmpty),

        // D. TABEL STOK PRODUK
        _buildProductStockTable(table, isDataEmpty),

        // E. STOCK TURNOVER INFO
        _buildStockTurnoverNotes(),
      ],
    );
  }

  Widget _buildStockValueCard(int value, int active, int empty) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5E3C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nilai Total Stok", style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(value), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text("berdasarkan harga modal asumsi 60%", style: TextStyle(color: Colors.white60, fontSize: 9)),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Text(
            "$active Produk Aktif  •  $empty Produk Habis",
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusDonut(Map<String, dynamic> status, int totalProducts, bool isEmpty) {
    final int aman = status['aman'] ?? 0;
    final int menipis = status['menipis'] ?? 0;
    final int habis = status['habis'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status Stok Saat Ini", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || totalProducts == 0)
            const _EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              iconColor: Colors.grey,
              title: "Belum ada data status stok",
              subtitle: "Data status produk tampil di sini.",
            )
          else ...[
            SizedBox(
              height: 130,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: [
                    PieChartSectionData(color: const Color(0xFF4CAF50), value: aman.toDouble(), title: "$aman", radius: 24, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(color: const Color(0xFFFF9800), value: menipis.toDouble(), title: "$menipis", radius: 24, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    PieChartSectionData(color: const Color(0xFFE53935), value: habis.toDouble(), title: "$habis", radius: 24, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop, color: Color(0xFF4CAF50), size: 16),
                Text("Stok Aman (>10)", style: TextStyle(fontSize: 9, color: Colors.grey)),
                SizedBox(width: 12),
                Icon(Icons.stop, color: Color(0xFFFF9800), size: 16),
                Text("Menipis (1-10)", style: TextStyle(fontSize: 9, color: Colors.grey)),
                SizedBox(width: 12),
                Icon(Icons.stop, color: Color(0xFFE53935), size: 16),
                Text("Habis", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockMovementsChart(List<dynamic> movements, bool isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pergerakan Stok 7 Hari", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (isEmpty || movements.isEmpty)
            const _EmptyState(
              icon: Icons.swap_vert_outlined,
              iconColor: Colors.grey,
              title: "Belum ada pergerakan stok",
              subtitle: "Data riwayat pergerakan stok 7 hari akan tampil di sini.",
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < movements.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(movements[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(movements.length, (idx) {
                    final double inbound = (movements[idx]['in'] as int).toDouble();
                    final double outbound = (movements[idx]['out'] as int).toDouble();
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(toY: inbound, color: const Color(0xFF4CAF50), width: 6),
                        BarChartRodData(toY: outbound, color: const Color(0xFFE53935), width: 6),
                      ],
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop, color: Color(0xFF4CAF50), size: 16),
              Text("Masuk", style: TextStyle(fontSize: 9, color: Colors.grey)),
              SizedBox(width: 16),
              Icon(Icons.stop, color: Color(0xFFE53935), size: 16),
              Text("Keluar", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductStockTable(List<dynamic> table, bool isEmpty) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detail Stok Per Produk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (isEmpty || table.isEmpty)
            const _EmptyState(
              icon: Icons.list_alt_rounded,
              iconColor: Colors.grey,
              title: "Belum ada produk di inventaris",
              subtitle: "Daftar produk dan status stok akan tertera di sini.",
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(120),
                border: TableBorder.all(color: Colors.grey.shade100),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF5E6D3)),
                    children: [
                      Padding(padding: EdgeInsets.all(10), child: Text("Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8B5E3C)))),
                      Padding(padding: EdgeInsets.all(10), child: Text("Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8B5E3C)))),
                      Padding(padding: EdgeInsets.all(10), child: Text("Nilai (HPP)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8B5E3C)))),
                      Padding(padding: EdgeInsets.all(10), child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8B5E3C)))),
                    ],
                  ),
                  ...List.generate(table.length, (idx) {
                    final row = table[idx];
                    final String name = row['name'] ?? '';
                    final int stock = row['stock'] ?? 0;
                    final int value = row['value'] ?? 0;
                    final String status = row['status'] ?? 'aman';

                    Color statusCol = const Color(0xFF4CAF50);
                    String statusLabel = "Aman";
                    if (status == 'menipis') {
                      statusCol = const Color(0xFFFF9800);
                      statusLabel = "Menipis";
                    } else if (status == 'habis') {
                      statusCol = const Color(0xFFE53935);
                      statusLabel = "Habis";
                    }

                    return TableRow(
                      decoration: BoxDecoration(color: idx % 2 == 0 ? Colors.white : const Color(0xFFF5E6D3).withOpacity(0.12)),
                      children: [
                        Padding(padding: const EdgeInsets.all(10), child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: const EdgeInsets.all(10), child: Text("$stock ${row['unit'] ?? 'pcs'}", style: const TextStyle(fontSize: 10))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(currencyFormatter.format(value), style: const TextStyle(fontSize: 10))),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: statusCol.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              statusLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusCol),
                            ),
                          ),
                        ),
                      ],
                    );
                  })
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockTurnoverNotes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF8B5E3C), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Perputaran stok membantu Anda mengidentifikasi produk terlaris sehingga produksi abon dapat diatur secara lebih efisien dan mengurangi risiko bahan baku terbuang sia-sia.",
              style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: HARIAN
// ==========================================
class _HarianTab extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const _HarianTab({required this.reportData});

  @override
  State<_HarianTab> createState() => _HarianTabState();
}

class _HarianTabState extends State<_HarianTab> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.reportData?['harian'] ?? {};
    final Map<String, dynamic> heatmap = data['calendar_heatmap'] ?? {};
    final List<dynamic> comparison = data['daily_comparison'] ?? [];

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final int todayTx = heatmap[dateKey] ?? 0;
    // Calculate estimates based on transactions
    final int todayRevenue = todayTx * 35000; // Mock estimate per transaction
    final int todayQty = todayTx * 2; // Mock item count

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // A. CALENDAR HEATMAP
        _CalendarHeatmap(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          heatmapData: heatmap,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
        ),

        // B. DAILY SUMMARY CARD
        _DailySummaryCard(
          selectedDay: _selectedDay,
          revenue: todayRevenue,
          transactions: todayTx,
          soldCount: todayQty,
        ),

        // C. DAILY COMPARISON (BAR CHART)
        _buildDailyComparisonChart(comparison),

        // D. STREAK MOTIVASI
        _buildStreakMotivation(heatmap.values.where((v) => v as int > 0).length),
      ],
    );
  }

  Widget _buildDailyComparisonChart(List<dynamic> comparison) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Perbandingan Aktivitas Hari", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (comparison.isEmpty)
            const _EmptyState(
              icon: Icons.bar_chart_rounded,
              iconColor: Colors.grey,
              title: "Belum ada riwayat harian",
              subtitle: "Data perbandingan harian akan terisi otomatis.",
            )
          else
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < comparison.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(comparison[val.toInt()]['label'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(comparison.length, (idx) {
                    final double rev = (comparison[idx]['revenue'] as int).toDouble();
                    final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDay) == comparison[idx]['date'];
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: rev,
                          color: isSelected ? const Color(0xFF5C3C24) : const Color(0xFFD4A853),
                          width: 8,
                        ),
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

  Widget _buildStreakMotivation(int activeDays) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A853), Color(0xFF8B5E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeDays > 0 ? "🔥 $activeDays Hari Aktif Bulan Ini!" : "Mulai Streak Penjualan Anda! 🔥",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Konsistensi adalah kunci sukses UMKM Abon Salakopi.",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: CALENDAR HEATMAP
// ==========================================
class _CalendarHeatmap extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<String, dynamic> heatmapData;
  final OnDaySelected onDaySelected;

  const _CalendarHeatmap({
    required this.focusedDay,
    required this.selectedDay,
    required this.heatmapData,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Aktivitas Penjualan Bulan Ini", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TableCalendar(
            locale: 'id_ID',
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focused) => _buildDayTile(day, false),
              todayBuilder: (context, day, focused) => _buildDayTile(day, true),
              selectedBuilder: (context, day, focused) => Container(
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B5E3C), width: 1.5), borderRadius: BorderRadius.circular(8)),
                child: _buildDayTile(day, false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("0 tx", style: TextStyle(fontSize: 9, color: Colors.grey)),
              SizedBox(width: 4),
              Icon(Icons.stop, color: Color(0xFFF5F5F5), size: 14),
              Icon(Icons.stop, color: Color(0xFFF5E6D3), size: 14),
              Icon(Icons.stop, color: Color(0xFF8B5E3C), size: 14),
              Icon(Icons.stop, color: Color(0xFF5C3C24), size: 14),
              SizedBox(width: 4),
              Text(">10 tx", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTile(DateTime day, bool isToday) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final count = heatmapData[key] ?? 0;

    Color bg = const Color(0xFFF5F5F5);
    if (count > 10) {
      bg = const Color(0xFF5C3C24);
    } else if (count > 5) {
      bg = const Color(0xFF8B5E3C);
    } else if (count > 0) {
      bg = const Color(0xFFF5E6D3);
    }

    Color textCol = count > 5 ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: const Color(0xFFD4A853), width: 1.2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        "${day.day}",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }
}

// ==========================================
// WIDGET: DAILY SUMMARY CARD
// ==========================================
class _DailySummaryCard extends StatelessWidget {
  final DateTime selectedDay;
  final int revenue;
  final int transactions;
  final int soldCount;

  const _DailySummaryCard({
    required this.selectedDay,
    required this.revenue,
    required this.transactions,
    required this.soldCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateLabel = DateFormat('d MMMM yyyy', 'id_ID').format(selectedDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ringkasan $dateLabel", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pendapatan", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(currencyFormatter.format(revenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Transaksi", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("$transactions tx", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Terjual", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("$soldCount item", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Jam Terpadat", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text("14:00 WIB", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: EXPORT LAPORAN BOTTOM SHEET
// ==========================================
class _ExportBottomSheet extends StatefulWidget {
  const _ExportBottomSheet();

  @override
  State<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet> {
  bool _optKeuangan = true;
  bool _optPenjualan = true;
  bool _optStok = false;
  bool _optHarian = false;

  String _format = "PDF"; // PDF | Excel | CSV

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 20),
          const Text("Ekspor Laporan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
          const Text("Pilih format & kategori laporan", style: TextStyle(fontSize: 11, color: Colors.grey)),
          const Divider(height: 24),

          // CHECKBOX KATEGORI
          CheckboxListTile(
            title: const Text("Laporan Keuangan", style: TextStyle(fontSize: 12)),
            value: _optKeuangan,
            activeColor: const Color(0xFF8B5E3C),
            onChanged: (val) => setState(() => _optKeuangan = val!),
          ),
          CheckboxListTile(
            title: const Text("Laporan Penjualan", style: TextStyle(fontSize: 12)),
            value: _optPenjualan,
            activeColor: const Color(0xFF8B5E3C),
            onChanged: (val) => setState(() => _optPenjualan = val!),
          ),
          CheckboxListTile(
            title: const Text("Laporan Stok", style: TextStyle(fontSize: 12)),
            value: _optStok,
            activeColor: const Color(0xFF8B5E3C),
            onChanged: (val) => setState(() => _optStok = val!),
          ),
          CheckboxListTile(
            title: const Text("Laporan Harian", style: TextStyle(fontSize: 12)),
            value: _optHarian,
            activeColor: const Color(0xFF8B5E3C),
            onChanged: (val) => setState(() => _optHarian = val!),
          ),
          const SizedBox(height: 16),

          // PILIH FORMAT TOGGLE
          const Text("Format File", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: ["PDF", "Excel", "CSV"].map((fmt) {
              final isSel = _format == fmt;

              Color accent = const Color(0xFF8B5E3C);
              if (fmt == 'PDF') accent = Colors.red;
              if (fmt == 'Excel') accent = Colors.green;
              if (fmt == 'CSV') accent = Colors.blue;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _format = fmt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent),
                      ),
                      child: Text(
                        fmt,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : accent),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // SUMMARY/PREVIEW
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Laporan berisi: ~4 halaman", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text("Ukuran file: ~120 KB", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BUTTONS
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur ekspor segera hadir! Terima kasih telah menunggu 🙏"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF8B5E3C),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Ekspor Sekarang", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Batal"),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE EMPTY STATE WIDGET
// ==========================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: iconColor.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
