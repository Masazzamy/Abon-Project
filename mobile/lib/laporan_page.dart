import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'app_colors.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;

  // State Variables
  String _selectedPeriodType = "Bulan"; // Hari, Minggu, Bulan, Custom
  DateTime _currentDate = DateTime(2026, 5, 23); // Standard base date matching truncation data
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  bool _showFloatingChip = true;
  bool _isInsightDismissed = false;

  // Tab 1: Finance parameters (Dynamic but starts with simulated values)
  double _profitEstimate = 0.0;
  double _totalRevenue = 0.0;
  double _totalCost = 0.0;
  int _transCount = 0;
  int _totalSoldQty = 0;

  // Chart view types
  String _financeChartType = "Bar"; // Bar, Line, Area

  // Tab 4: Calendar Heatmap parameters
  DateTime _focusedCalendarDay = DateTime(2026, 5, 23);
  DateTime _selectedCalendarDay = DateTime(2026, 5, 23);

  // Sorting for Stock table
  String _stockSortColumn = "Produk";
  bool _stockSortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 120) {
        if (_showFloatingChip) {
          setState(() {
            _showFloatingChip = false;
          });
        }
      } else {
        if (!_showFloatingChip) {
          setState(() {
            _showFloatingChip = true;
          });
        }
      }
    });

    _simulasikanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _simulasikanData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate 800ms shimmer load
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Simulated premium figures for the selected base period (May 2026 / 23 May 2026)
          _totalRevenue = 15850000;
          _totalCost = 9640000;
          _profitEstimate = _totalRevenue - _totalCost;
          _transCount = 142;
          _totalSoldQty = 540;
        });
      }
    });
  }

  void _adjustPeriod(int offset) {
    setState(() {
      if (_selectedPeriodType == "Hari") {
        _currentDate = _currentDate.add(Duration(days: offset));
      } else if (_selectedPeriodType == "Minggu") {
        _currentDate = _currentDate.add(Duration(days: offset * 7));
      } else if (_selectedPeriodType == "Bulan") {
        int nextMonth = _currentDate.month + offset;
        int nextYear = _currentDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        } else if (nextMonth < 1) {
          nextMonth = 12;
          nextYear -= 1;
        }
        _currentDate = DateTime(nextYear, nextMonth, _currentDate.day);
      }
      _simulasikanData();
    });
  }

  String get _periodLabel {
    if (_selectedPeriodType == "Hari") {
      return _formatDateIndo(_currentDate);
    } else if (_selectedPeriodType == "Minggu") {
      final start = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}";
    } else if (_selectedPeriodType == "Bulan") {
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return "${months[_currentDate.month - 1]} ${_currentDate.year}";
    } else {
      if (_customDateRange == null) {
        return "Pilih Tanggal Custom";
      }
      return "${DateFormat('d MMM').format(_customDateRange!.start)} - ${DateFormat('d MMM yyyy').format(_customDateRange!.end)}";
    }
  }

  String _formatDateIndo(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return "${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}";
  }

  double get _marginPercent {
    if (_totalRevenue == 0) return 0.0;
    return (_profitEstimate / _totalRevenue);
  }

  // Open Export sheet
  void _openExportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExportBottomSheet(activePeriodLabel: _periodLabel),
    );
  }

  // Sorting logic for Stock table
  List<Map<String, dynamic>> _getSortedStockData() {
    // Mock stock data
    final List<Map<String, dynamic>> list = [
      {'nama': 'Abon Sapi Original 250g', 'stok': 25, 'nilai': 1375000, 'status': 'Aman'},
      {'nama': 'Abon Sapi Pedas 250g', 'stok': 18, 'nilai': 1080000, 'status': 'Aman'},
      {'nama': 'Abon Ayam Original 150g', 'stok': 30, 'nilai': 1050000, 'status': 'Aman'},
      {'nama': 'Abon Ayam Pedas 150g', 'stok': 5, 'nilai': 200000, 'status': 'Menipis'},
      {'nama': 'Camilan Salakopi Crispy', 'stok': 0, 'nilai': 0, 'status': 'Habis'},
    ];

    list.sort((a, b) {
      dynamic valA = a[_stockSortColumn == "Produk"
          ? 'nama'
          : _stockSortColumn == "Stok"
              ? 'stok'
              : _stockSortColumn == "Nilai"
                  ? 'nilai'
                  : 'status'];
      dynamic valB = b[_stockSortColumn == "Produk"
          ? 'nama'
          : _stockSortColumn == "Stok"
              ? 'stok'
              : _stockSortColumn == "Nilai"
                  ? 'nilai'
                  : 'status'];

      if (_stockSortAscending) {
        return valA.compareTo(valB);
      } else {
        return valB.compareTo(valA);
      }
    });

    return list;
  }

  void _sortStock(String columnName) {
    setState(() {
      if (_stockSortColumn == columnName) {
        _stockSortAscending = !_stockSortAscending;
      } else {
        _stockSortColumn = columnName;
        _stockSortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _simulasikanData();
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 1. Header Section
                _HeaderSection(onExportPressed: _openExportBottomSheet),

                // 2. Period Selector Bar (Sticky dynamic header wrapper)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // AI-style Static Business Insight Card (if not dismissed)
                      if (!_isInsightDismissed)
                        _InsightCard(
                          message: _totalRevenue > 0
                              ? "💡 Omzet bulanan bertumbuh sebesar 12% didominasi oleh Abon Sapi Original 250g. Rata-rata jam transaksi terpadat di antara pukul 14:00 - 16:00 WIB."
                              : "Mulai catat transaksi untuk mendapatkan insight bisnis Anda",
                          onDismiss: () {
                            setState(() {
                              _isInsightDismissed = true;
                            });
                          },
                        ),

                      _PeriodSelectorBar(
                        selectedType: _selectedPeriodType,
                        periodLabel: _periodLabel,
                        onTypeChanged: (type) async {
                          setState(() {
                            _selectedPeriodType = type;
                          });
                          if (type == "Custom") {
                            final now = DateTime.now();
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: now.subtract(const Duration(days: 365)),
                              lastDate: now,
                              initialDateRange: _customDateRange,
                            );
                            if (range != null) {
                              setState(() {
                                _customDateRange = range;
                              });
                            } else {
                              setState(() {
                                _selectedPeriodType = "Bulan";
                              });
                            }
                          }
                          _simulasikanData();
                        },
                        onAdjust: _adjustPeriod,
                      ),
                    ],
                  ),
                ),

                // 3. Tab Bar (Sticky)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabHeaderDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey[500],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3.5,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.grey.withOpacity(0.15),
                      isScrollable: false,
                      tabs: const [
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on_rounded, size: 14), SizedBox(width: 4), Text("Keuangan")])),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_rounded, size: 14), SizedBox(width: 4), Text("Penjualan")])),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_rounded, size: 14), SizedBox(width: 4), Text("Stok")])),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_rounded, size: 14), SizedBox(width: 4), Text("Harian")])),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(_KeuanganTab(
                  isLoading: _isLoading,
                  revenue: _totalRevenue,
                  cost: _totalCost,
                  profit: _profitEstimate,
                  margin: _marginPercent,
                  transCount: _transCount,
                  chartType: _financeChartType,
                  onChartTypeChanged: (type) {
                    setState(() {
                      _financeChartType = type;
                    });
                  },
                )),
                _buildTabContent(_PenjualanTab(
                  isLoading: _isLoading,
                  totalSoldQty: _totalSoldQty,
                  revenue: _totalRevenue,
                )),
                _buildTabContent(_StokTab(
                  isLoading: _isLoading,
                  sortedStock: _getSortedStockData(),
                  onSort: _sortStock,
                  sortColumn: _stockSortColumn,
                  sortAscending: _stockSortAscending,
                )),
                _buildTabContent(_HarianTab(
                  isLoading: _isLoading,
                  selectedDay: _selectedCalendarDay,
                  focusedDay: _focusedCalendarDay,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedCalendarDay = selected;
                      _focusedCalendarDay = focused;
                    });
                  },
                )),
              ],
            ),
          ),
        ),
      ),
      // Floating dynamic period badge chip that opens period type trigger
      floatingActionButton: AnimatedOpacity(
        opacity: _showFloatingChip ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: AbsorbPointer(
          absorbing: !_showFloatingChip,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Open simple period picker sheet
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Pilih Cakupan Periode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.today_rounded, color: AppColors.primary),
                        title: const Text("Harian"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedPeriodType = "Hari");
                          _simulasikanData();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                        title: const Text("Mingguan"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedPeriodType = "Minggu");
                          _simulasikanData();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        title: const Text("Bulanan"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedPeriodType = "Bulan");
                          _simulasikanData();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 16),
            label: Text(
              _selectedPeriodType == "Bulan" ? DateFormat('MMMM yyyy').format(_currentDate) : _selectedPeriodType,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Widget tab) {
    return _isLoading ? const _ShimmerLaporanTab() : tab;
  }
}

// =========================================================================
// 1. HEADER SECTION WIDGET (SliverAppBar)
// =========================================================================
class _HeaderSection extends StatelessWidget {
  final VoidCallback onExportPressed;

  const _HeaderSection({required this.onExportPressed});

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
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
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
                    'Laporan Bisnis',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analisis mendalam usaha Anda',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onExportPressed,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(12),
                  shape: const CircleBorder(),
                  elevation: 3,
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. PERIOD SELECTOR BAR
// =========================================================================
class _PeriodSelectorBar extends StatelessWidget {
  final String selectedType;
  final String periodLabel;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onAdjust;

  const _PeriodSelectorBar({
    required this.selectedType,
    required this.periodLabel,
    required this.onTypeChanged,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          // Period Toggle Pill Choice
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Hari", "Minggu", "Bulan", "Custom"].map((type) {
              final active = selectedType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    onPressed: () => onTypeChanged(type),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: active ? AppColors.primary : Colors.white,
                      side: BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: active ? 2 : 0,
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Date Navigation row (if not custom)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedType != "Custom")
                IconButton(
                  onPressed: () => onAdjust(-1),
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                )
              else
                const SizedBox(width: 48),
              
              Expanded(
                child: Text(
                  periodLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (selectedType != "Custom")
                IconButton(
                  onPressed: () => onAdjust(1),
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// SLIVER PERSISTENT TAB BAR DELEGATE
// =========================================================================
class _SliverTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabHeaderDelegate(this.tabBar);

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
  bool shouldRebuild(covariant _SliverTabHeaderDelegate oldDelegate) => false;
}

// =========================================================================
// COUNTER ANIMATOR FOR FINANCIAL FIGURES
// =========================================================================
class _AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    this.prefix = "",
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final formatted = currencyFormatter.format(val.toInt());
        return Text(
          "$prefix$formatted",
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

// =========================================================================
// AI STYLE INSIGHT WIDGET
// =========================================================================
class _InsightCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _InsightCard({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary.withOpacity(0.4), const Color(0xFFFAF2E8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Insight Bisnis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 11, color: Color(0xFF6B4E38), height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 1: KEUANGAN
// =========================================================================
class _KeuanganTab extends StatelessWidget {
  final bool isLoading;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final int transCount;
  
  final String chartType;
  final ValueChanged<String> onChartTypeChanged;

  const _KeuanganTab({
    required this.isLoading,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.transCount,
    required this.chartType,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final marginLabel = (margin * 100).toStringAsFixed(1);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // A. HERO PROFIT CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF5A3D25)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Estimasi Laba Bersih", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _AnimatedCounter(
                value: profit,
                prefix: "Rp ",
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubHeroInfo("Pendapatan", revenue, Colors.lightGreenAccent),
                  Container(width: 1.5, height: 28, color: Colors.white24),
                  _buildSubHeroInfo("Modal Pokok", cost, const Color(0xFFFFB3B3)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Margin Keuntungan", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                  Text("$marginLabel%", style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: margin,
                  backgroundColor: Colors.white12,
                  color: AppColors.accent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // B. FINANCIAL SUMMARY CARDS (2x2 grid)
        _FinancialSummaryCards(revenue: revenue, cost: cost, transCount: transCount),
        const SizedBox(height: 24),

        // C. REVENUE vs COST CHART
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pendapatan vs Modal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  
                  // Toggle chart style
                  Container(
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: ["Bar", "Line", "Area"].map((mode) {
                        final active = chartType == mode;
                        return GestureDetector(
                          onTap: () => onChartTypeChanged(mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)] : null,
                            ),
                            child: Text(mode, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? AppColors.primary : Colors.grey)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),



              SizedBox(
                height: 160,
                child: chartType == "Bar"
                    ? BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: _buildChartTitles(),
                          barGroups: [
                            _buildGroupBar(0, 1.2, 0.7),
                            _buildGroupBar(1, 2.4, 1.3),
                            _buildGroupBar(2, 1.8, 1.1),
                            _buildGroupBar(3, 3.8, 2.2),
                            _buildGroupBar(4, 3.0, 1.8),
                            _buildGroupBar(5, 5.2, 3.1),
                          ],
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: _buildChartTitles(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [FlSpot(0, 1.2), FlSpot(1, 2.4), FlSpot(2, 1.8), FlSpot(3, 3.8), FlSpot(4, 3.0), FlSpot(5, 5.2)],
                              color: AppColors.primary,
                              barWidth: 3,
                              isCurved: true,
                              belowBarData: BarAreaData(show: chartType == "Area", color: AppColors.primary.withOpacity(0.12)),
                            ),
                            LineChartBarData(
                              spots: const [FlSpot(0, 0.7), FlSpot(1, 1.3), FlSpot(2, 1.1), FlSpot(3, 2.2), FlSpot(4, 1.8), FlSpot(5, 3.1)],
                              color: AppColors.accent,
                              barWidth: 3,
                              isCurved: true,
                              belowBarData: BarAreaData(show: chartType == "Area", color: AppColors.accent.withOpacity(0.12)),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem("Pendapatan", AppColors.primary),
                  const SizedBox(width: 20),
                  _buildLegendItem("Modal", AppColors.accent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // D. BREAKDOWN KATEGORI (Donut/Pie Chart)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Kontribusi Per Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 36,
                            sections: [
                              PieChartSectionData(value: 45, color: AppColors.primary, radius: 18, showTitle: false),
                              PieChartSectionData(value: 25, color: const Color(0xFFB37B50), radius: 18, showTitle: false),
                              PieChartSectionData(value: 20, color: AppColors.accent, radius: 18, showTitle: false),
                              PieChartSectionData(value: 10, color: AppColors.secondary, radius: 18, showTitle: false),
                            ],
                          ),
                        ),
                        const Center(
                          child: Text("Total\n100%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      children: [
                        _buildCategoryRow("Abon Sapi Ori", "45%", AppColors.primary),
                        _buildCategoryRow("Abon Sapi Pedas", "25%", const Color(0xFFB37B50)),
                        _buildCategoryRow("Abon Ayam Ori", "20%", AppColors.accent),
                        _buildCategoryRow("Camilan Crispy", "10%", AppColors.secondary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // E. CATATAN KEUANGAN
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF8F4),
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Data laba merupakan estimasi berdasarkan harga modal pokok produksi yang diinput. Untuk keperluan laporan pajak formal, silakan konsultasikan dengan akuntan Anda.",
                  style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSubHeroInfo(String title, double val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        _AnimatedCounter(
          value: val,
          prefix: "Rp ",
          style: TextStyle(color: valColor, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoryRow(String name, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
        ],
      ),
    );
  }

  BarChartGroupData _buildGroupBar(int x, double val1, double val2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: val1, color: AppColors.primary, width: 7, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: val2, color: AppColors.accent, width: 7, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  FlTitlesData _buildChartTitles() {
    final list = ["Des", "Jan", "Feb", "Mar", "Apr", "Mei"];
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx >= 0 && idx < 6) {
              return Text(list[idx], style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold));
            }
            return const Text("");
          },
        ),
      ),
    );
  }
}

class _FinancialSummaryCards extends StatelessWidget {
  final double revenue;
  final double cost;
  final int transCount;

  const _FinancialSummaryCards({
    required this.revenue,
    required this.cost,
    required this.transCount,
  });

  @override
  Widget build(BuildContext context) {
    final double avgPerDay = revenue / 30;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          title: "Total Pendapatan",
          value: revenue,
          subText: "$transCount transaksi",
          trendText: "+8.2% vs bln lalu",
          trendColor: AppColors.success,
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.success,
        ),
        _buildSummaryCard(
          title: "Total Modal HPP",
          value: cost,
          subText: "Harga pokok produksi",
          trendText: "60% dari omzet",
          trendColor: AppColors.alert,
          icon: Icons.trending_down_rounded,
          iconColor: AppColors.alert,
        ),
        _buildSummaryCard(
          title: "Rata-rata / Hari",
          value: avgPerDay,
          subText: "Bulan aktif",
          trendText: "Rasio stabil",
          trendColor: Colors.blue,
          icon: Icons.calendar_today_rounded,
          iconColor: AppColors.primary,
        ),
        _buildSummaryCard(
          title: "Transaksi Baru",
          value: transCount.toDouble(),
          subText: "Pembeli dilayani",
          trendText: "+12% vs bln lalu",
          trendColor: AppColors.success,
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.blue,
          isCurrency: false,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required String subText,
    required String trendText,
    required Color trendColor,
    required IconData icon,
    required Color iconColor,
    bool isCurrency = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              Text(
                trendText,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: trendColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          _AnimatedCounter(
            value: value,
            prefix: isCurrency ? "Rp " : "",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(subText, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 2: PENJUALAN
// =========================================================================
class _PenjualanTab extends StatelessWidget {
  final bool isLoading;
  final int totalSoldQty;
  final double revenue;

  const _PenjualanTab({
    required this.isLoading,
    required this.totalSoldQty,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // A. SALES PERFORMANCE BANNER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.success, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Terjual: $totalSoldQty item", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                    const SizedBox(height: 2),
                    const Text("dari 5 jenis produk abon berbeda", style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // B. TREN PENJUALAN CHART
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Tren Kuantitas Terjual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 20),

              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: _buildDaysTitles(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [FlSpot(0, 10), FlSpot(1, 25), FlSpot(2, 18), FlSpot(3, 45), FlSpot(4, 30), FlSpot(5, 55), FlSpot(6, 40)],
                        color: AppColors.primary,
                        barWidth: 4,
                        isCurved: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.01)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // C. TOP 5 PRODUK TERLARIS
        _TopProductsList(revenue: revenue),
        const SizedBox(height: 20),

        // D. PENJUALAN PER JAM (Heatmap style)
        _HourlyHeatmap(),
        const SizedBox(height: 20),

        // E. METODE PEMBAYARAN
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Metode Pembayaran Terpopuler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 16),

              _buildPaymentProgress("Tunai (Cash)", 0.35, "Rp 5.547.500 (45 Trans)", AppColors.primary),
              _buildPaymentProgress("Transfer Bank", 0.25, "Rp 3.962.500 (32 Trans)", AppColors.accent),
              _buildPaymentProgress("QRIS / E-Wallet", 0.40, "Rp 6.340.000 (65 Trans)", AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPaymentProgress(String name, double pct, String subText, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              Text("${(pct * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(subText, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  FlTitlesData _buildDaysTitles() {
    final list = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx >= 0 && idx < 7) {
              return Text(list[idx], style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold));
            }
            return const Text("");
          },
        ),
      ),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final double revenue;

  const _TopProductsList({required this.revenue});

  @override
  Widget build(BuildContext context) {
    // Simulated top 5 list
    final List<Map<String, dynamic>> products = [
      {'nama': 'Abon Sapi Original 250g', 'qty': 240, 'val': 7200000, 'pct': 1.0, 'badge': '🥇'},
      {'nama': 'Abon Sapi Pedas 250g', 'qty': 130, 'val': 3900000, 'pct': 0.54, 'badge': '🥈'},
      {'nama': 'Abon Ayam Original 150g', 'qty': 95, 'val': 2850000, 'pct': 0.40, 'badge': '🥉'},
      {'nama': 'Abon Ayam Pedas 150g', 'qty': 50, 'val': 1500000, 'pct': 0.21, 'badge': '4'},
      {'nama': 'Camilan Salakopi Crispy', 'qty': 25, 'val': 400000, 'pct': 0.10, 'badge': '5'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Produk Terlaris", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 16),

          ...products.map((p) {
            final String badge = p['badge'] as String;
            final isMedal = badge == '🥇' || badge == '🥈' || badge == '🥉';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Badge rank
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isMedal ? Colors.transparent : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: isMedal ? 18 : 10,
                        fontWeight: isMedal ? FontWeight.normal : FontWeight.bold,
                        color: isMedal ? null : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(p['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Terjual: ${p['qty']} pcs", style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                            Text("Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(p['val'])}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: p['pct'] as double,
                            minHeight: 5,
                            backgroundColor: Colors.grey[100],
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _HourlyHeatmap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 24 cells for hours 00-23
    final List<int> transactions = [
      0, 0, 0, 0, 0, 0,
      1, 2, 4, 3, 6, 8,
      12, 10, 15, 18, 14, 11,
      8, 5, 2, 1, 0, 0
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Jam Penjualan Tersibuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 16),

          // Heatmap grid (4 rows of 6 cells)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.3,
            ),
            itemCount: 24,
            itemBuilder: (context, index) {
              final count = transactions[index];
              Color cellColor = const Color(0xFFF5F5F5); // None
              if (count > 0 && count <= 4) {
                cellColor = AppColors.secondary.withOpacity(0.5);
              } else if (count > 4 && count <= 10) {
                cellColor = AppColors.secondary;
              } else if (count > 10 && count <= 15) {
                cellColor = AppColors.primary.withOpacity(0.75);
              } else if (count > 15) {
                cellColor = AppColors.primary;
              }

              return Tooltip(
                message: "Jam ${index.toString().padLeft(2, '0')}:00 - $count transaksi",
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.08)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: count > 10 ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Label
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("00:00 (Sepi)", style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text("15:00 (Sibuk)", style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
              Text("23:00 (Tutup)", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 3: STOK
// =========================================================================
class _StokTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> sortedStock;
  final ValueChanged<String> onSort;
  final String sortColumn;
  final bool sortAscending;

  const _StokTab({
    required this.isLoading,
    required this.sortedStock,
    required this.onSort,
    required this.sortColumn,
    required this.sortAscending,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // A. STOCK VALUE CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFFB37B50)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Nilai Total Aset Stok", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                "Rp 3.705.000",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text("berdasarkan modal pokok HPP produk aktif", style: TextStyle(color: Colors.white60, fontSize: 9)),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("4 Produk Aktif", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("1 Produk Stok Habis", style: TextStyle(color: Color(0xFFFFB3B3), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // B. STOCK STATUS CHART
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Status Ketersediaan Stok", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(value: 3, color: AppColors.success, radius: 15, showTitle: false),
                          PieChartSectionData(value: 1, color: AppColors.warning, radius: 15, showTitle: false),
                          PieChartSectionData(value: 1, color: AppColors.alert, radius: 15, showTitle: false),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      children: [
                        _buildStatusLegend("Stok Aman (>10)", "3 Produk", AppColors.success),
                        _buildStatusLegend("Stok Menipis (1-10)", "1 Produk", AppColors.warning),
                        _buildStatusLegend("Stok Habis (0)", "1 Produk", AppColors.alert),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // C. PERGERAKAN STOK CHART
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Pergerakan Stok 7 Hari", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 16),

              SizedBox(
                height: 130,
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
                            final list = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < 7) {
                              return Text(list[idx], style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold));
                            }
                            return const Text("");
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      _buildDoubleBar(0, 10, 5),
                      _buildDoubleBar(1, 0, 12),
                      _buildDoubleBar(2, 20, 8),
                      _buildDoubleBar(3, 5, 10),
                      _buildDoubleBar(4, 0, 15),
                      _buildDoubleBar(5, 30, 20),
                      _buildDoubleBar(6, 15, 6),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)), const SizedBox(width: 6), const Text("Stok Masuk", style: TextStyle(fontSize: 9, color: Colors.grey))]),
                  const SizedBox(width: 20),
                  Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.alert, shape: BoxShape.circle)), const SizedBox(width: 6), const Text("Stok Keluar", style: TextStyle(fontSize: 9, color: Colors.grey))]),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // D. TABEL STOK PRODUK (Sortable)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text("Detail Stok Per Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  columnSpacing: 22,
                  headingRowColor: MaterialStateProperty.all(AppColors.secondary.withOpacity(0.3)),
                  columns: [
                    DataColumn(
                      label: Row(children: [const Text("Produk"), _buildSortIcon("Produk")]),
                      onSort: (colIndex, asc) => onSort("Produk"),
                    ),
                    DataColumn(
                      label: Row(children: [const Text("Stok"), _buildSortIcon("Stok")]),
                      onSort: (colIndex, asc) => onSort("Stok"),
                    ),
                    DataColumn(
                      label: Row(children: [const Text("Nilai"), _buildSortIcon("Nilai")]),
                      onSort: (colIndex, asc) => onSort("Nilai"),
                    ),
                    const DataColumn(label: Text("Status")),
                  ],
                  rows: sortedStock.map((row) {
                    final status = row['status'] as String;
                    final Color statusColor = status == "Aman"
                        ? AppColors.success
                        : status == "Menipis"
                            ? AppColors.warning
                            : AppColors.alert;

                    return DataRow(
                      cells: [
                        DataCell(Text(row['nama'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataCell(Text("${row['stok']} pcs", style: const TextStyle(fontSize: 11))),
                        DataCell(Text("Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(row['nilai'])}", style: const TextStyle(fontSize: 11))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // E. STOCK TURNOVER INFO
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Memantau perputaran stok membantu Anda mengetahui produk mana yang paling cepat habis dan perlu diprioritaskan produksinya.",
                  style: TextStyle(fontSize: 10.5, color: AppColors.primary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatusLegend(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildSortIcon(String columnName) {
    if (sortColumn == columnName) {
      return Icon(sortAscending ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primary);
    }
    return const Icon(Icons.arrow_drop_up_rounded, size: 18, color: Colors.grey);
  }

  BarChartGroupData _buildDoubleBar(int x, double v1, double v2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: v1, color: AppColors.success, width: 6),
        BarChartRodData(toY: v2, color: AppColors.alert, width: 6),
      ],
    );
  }
}

// =========================================================================
// TAB 4: HARIAN
// =========================================================================
class _HarianTab extends StatelessWidget {
  final bool isLoading;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime, DateTime) onDaySelected;

  const _HarianTab({
    required this.isLoading,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // A. CALENDAR HEATMAP (using table_calendar package)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text("Aktivitas Transaksi Bulan Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              ),
              TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime(2026, 1, 1),
                lastDay: DateTime(2026, 12, 31),
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: onDaySelected,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
              ),

              // Calendar custom color heatmap legend
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Sepi", style: TextStyle(fontSize: 8, color: Colors.grey)),
                    SizedBox(width: 6),
                    _HeatDot(color: Colors.grey),
                    SizedBox(width: 4),
                    _HeatDot(color: Color(0xFFF5E6D3)),
                    SizedBox(width: 4),
                    _HeatDot(color: Color(0xFFD4A853)),
                    SizedBox(width: 4),
                    _HeatDot(color: Color(0xFF8B5E3C)),
                    SizedBox(width: 6),
                    Text("Ramai", style: TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // B. DAILY SUMMARY CARD
        _DailySummaryCard(selectedDay: selectedDay),
        const SizedBox(height: 20),

        // C. DAILY TRANSACTION LIST
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Daftar Transaksi (${DateFormat('d MMMM').format(selectedDay)})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              const SizedBox(height: 12),

              _buildDailyTransactionItem("14:30 WIB", "Abon Sapi Original 250g", 2, 70000),
              _buildDailyTransactionItem("11:15 WIB", "Abon Sapi Pedas 250g", 1, 35000),
              _buildDailyTransactionItem("09:40 WIB", "Abon Ayam Original 150g", 3, 75000),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // D. DAILY COMPARISON (fl_chart)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Perbandingan Kinerja Harian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 16),

              SizedBox(
                height: 120,
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
                            final list = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < 7) {
                              return Text(list[idx], style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold));
                            }
                            return const Text("");
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      _buildSingleBar(0, 1.2, false),
                      _buildSingleBar(1, 0.8, false),
                      _buildSingleBar(2, 2.4, false),
                      _buildSingleBar(3, 1.5, false),
                      _buildSingleBar(4, 3.2, false),
                      _buildSingleBar(5, 4.5, true), // Active selected day
                      _buildSingleBar(6, 2.8, false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // E. STREAK MOTIVASI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFFB37B50)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🔥 Penjualan Berturut-turut!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    SizedBox(height: 2),
                    Text("Anda telah mencatat transaksi aktif 5 hari berturut-turut. Pertahankan streak Anda!", style: TextStyle(fontSize: 10, color: Color(0xD9FFFFFF))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDailyTransactionItem(String time, String title, int qty, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text("$qty pcs", style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
                ],
              )
            ],
          ),
          Text(
            "Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(total)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
          )
        ],
      ),
    );
  }

  BarChartGroupData _buildSingleBar(int x, double val, bool active) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: val,
          color: active ? AppColors.primary : AppColors.secondary,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}

class _HeatDot extends StatelessWidget {
  final Color color;

  const _HeatDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _DailySummaryCard extends StatelessWidget {
  final DateTime selectedDay;

  const _DailySummaryCard({required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Ringkasan (${DateFormat('dd MMMM yyyy').format(selectedDay)})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildItem("Pendapatan", currencyFormatter.format(180000), AppColors.success),
              ),
              Expanded(
                child: _buildItem("Total Transaksi", "6", AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildItem("Produk Terjual", "12 item", AppColors.accent),
              ),
              Expanded(
                child: _buildItem("Jam Tersibuk", "14:00 - 15:00", Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

// =========================================================================
// SHIMMER TAB LOADER
// =========================================================================
class _ShimmerLaporanTab extends StatelessWidget {
  const _ShimmerLaporanTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 160,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          ),
        ),
        const SizedBox(height: 20),

        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// =========================================================================
// EXPORT BOTTOM SHEET
// =========================================================================
class _ExportBottomSheet extends StatefulWidget {
  final String activePeriodLabel;

  const _ExportBottomSheet({required this.activePeriodLabel});

  @override
  State<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet> {
  bool _includeFinance = true;
  bool _includeSales = true;
  bool _includeStock = false;
  bool _includeDaily = false;

  String _format = "PDF"; // PDF, Excel, CSV

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 18),

          const Text("Ekspor Laporan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
          const SizedBox(height: 4),
          const Text("Pilih data laporan & format file yang diinginkan", style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const Divider(height: 24),

          // Checkboxes
          _buildCheckbox("Laporan Keuangan", _includeFinance, (val) => setState(() => _includeFinance = val ?? false)),
          _buildCheckbox("Laporan Penjualan", _includeSales, (val) => setState(() => _includeSales = val ?? false)),
          _buildCheckbox("Laporan Stok & Inventaris", _includeStock, (val) => setState(() => _includeStock = val ?? false)),
          _buildCheckbox("Laporan Harian / Buku Kas", _includeDaily, (val) => setState(() => _includeDaily = val ?? false)),
          const SizedBox(height: 16),

          // Format selectors
          const Text("Format File", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFormatPill("PDF", Colors.red),
              const SizedBox(width: 8),
              _buildFormatPill("Excel", Colors.green),
              const SizedBox(width: 8),
              _buildFormatPill("CSV", Colors.blue),
            ],
          ),
          const SizedBox(height: 20),

          // Period info preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Periode: ${widget.activePeriodLabel} • Format: $_format",
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Batal", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fitur ekspor segera hadir! Terima kasih telah menunggu 🙏"),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Ekspor Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildFormatPill(String name, Color themeColor) {
    final active = _format == name;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _format = name),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? themeColor.withOpacity(0.12) : Colors.white,
            border: Border.all(color: active ? themeColor : Colors.grey.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: active ? themeColor : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
