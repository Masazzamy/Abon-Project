import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false, // Let header gradient flow into status bar
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Section
                    const _HeaderSection(userName: 'Masazzamy'),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 2. Summary Cards Grid (2x2)
                          const _SummaryCards(),
                          const SizedBox(height: 24),

                          // 3. Weekly Sales Chart
                          const _WeeklySalesChart(),
                          const SizedBox(height: 24),

                          // 4. Low Stock Alert Section
                          const _LowStockAlertSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 5. Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF8B5E3C), // Coklat keemasan active color
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          elevation: 0,
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
              icon: Icon(Icons.monetization_on_outlined),
              activeIcon: Icon(Icons.monetization_on),
              label: 'Penjualan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Pergerakan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}

/// 1. HEADER SECTION (with background gradient coklat keemasan)
class _HeaderSection extends StatelessWidget {
  final String userName;

  const _HeaderSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, statusBarHeight + 16.0, 20.0, 28.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5E3C), // Darker Golden Brown
            Color(0xFFB37B50), // Lighter Golden Brown
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.0),
          bottomRight: Radius.circular(32.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row with Notification badge and Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Welcome text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Action items (Notification & Profile Avatar)
              Row(
                children: [
                  // Notification Icon with badge
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 8),
                  // User Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(128), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Current Date display
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(220),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Generate current Indonesian date format (e.g. Kamis, 21 Mei 2026)
  String _getFormattedDate() {
    final now = DateTime.now();
    
    const List<String> days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    // Handle day of week (DateTime.weekday is 1-indexed, Monday=1, Sunday=7)
    final dayName = days[now.weekday - 1];
    final dayNum = now.day;
    final monthName = months[now.month - 1];
    final year = now.year;

    return '$dayName, $dayNum $monthName $year';
  }
}

/// 2. SUMMARY CARDS SECTION (2x2 grid, card putih dengan shadow halus)
class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _SummaryCard(
                title: 'Penjualan Hari Ini',
                value: 'Rp 1.250.000',
                icon: Icons.payments_outlined,
                iconBgColor: Color(0xFFFAF2EC),
                iconColor: Color(0xFF8B5E3C),
                statusLabel: 'Stabil dari kemarin',
                statusColor: Colors.grey,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Transaksi',
                value: '45',
                icon: Icons.receipt_long_outlined,
                iconBgColor: Color(0xFFE8F5E9),
                iconColor: Color(0xFF388E3C),
                statusLabel: ' naik 12%',
                statusColor: Color(0xFF388E3C),
                statusIcon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(
              child: _SummaryCard(
                title: 'Total Produk',
                value: '12',
                icon: Icons.grid_view_outlined,
                iconBgColor: Color(0xFFFAF2EC),
                iconColor: Color(0xFF8B5E3C),
                statusLabel: '3 produk baru',
                statusColor: Color(0xFF8B5E3C),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Stok Menipis',
                value: '4',
                icon: Icons.warning_amber_rounded,
                iconBgColor: Color(0xFFFFEBEE),
                iconColor: Color(0xFFD32F2F),
                statusLabel: 'Perlu restock',
                statusColor: Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String statusLabel;
  final Color statusColor;
  final IconData? statusIcon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.statusLabel,
    required this.statusColor,
    this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha(20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main bold value
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          // Status label
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusIcon != null) ...[
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 2),
              ],
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. WEEKLY SALES CHART
class _WeeklySalesChart extends StatelessWidget {
  const _WeeklySalesChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha(20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penjualan Mingguan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '7 hari terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const Text(
                'Rp 8.450.000',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5E3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // fl_chart container
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Sen', style: style);
                            break;
                          case 1:
                            text = const Text('Sel', style: style);
                            break;
                          case 2:
                            text = const Text('Rab', style: style);
                            break;
                          case 3:
                            text = const Text('Kam', style: style);
                            break;
                          case 4:
                            text = const Text('Jum', style: style);
                            break;
                          case 5:
                            text = const Text('Sab', style: style);
                            break;
                          case 6:
                            text = const Text('Min', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1.5,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        );
                        if (value == 0) return const SizedBox();
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text('${value.toStringAsFixed(1)}Jt', style: style),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.2),
                      FlSpot(1, 2.4),
                      FlSpot(2, 1.8),
                      FlSpot(3, 3.8),
                      FlSpot(4, 3.0),
                      FlSpot(5, 5.2),
                      FlSpot(6, 4.5),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5E3C),
                        Color(0xFFD4A35B),
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFF8B5E3C),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5E3C).withAlpha(51),
                          const Color(0xFFD4A35B).withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
}

/// 4. LOW STOCK ALERT SECTION
class _LowStockAlertSection extends StatelessWidget {
  const _LowStockAlertSection();

  @override
  Widget build(BuildContext context) {
    // Dummy products data for warning
    final List<Map<String, dynamic>> lowStockProducts = [
      {'name': 'Abon Sapi Original 250g', 'stock': 3},
      {'name': 'Abon Ayam Pedas 150g', 'stock': 2},
      {'name': 'Abon Sapi Spesial 100g', 'stock': 4},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withAlpha(20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Merah Muda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F1), // Light pink/red background
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD32F2F),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Peringatan Stok Menipis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: lowStockProducts.map((product) {
                return _buildStockItem(
                  context,
                  product['name'] as String,
                  product['stock'] as int,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(BuildContext context, String productName, int stockCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Sisa stok: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$stockCount pcs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F), // Bold red
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Restock Button
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () {
                // Show Restock Dialog / Scaffold message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permintaan restock untuk "$productName" telah diajukan.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8B5E3C), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Restock',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5E3C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
