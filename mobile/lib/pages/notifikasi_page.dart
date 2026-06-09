import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:badges/badges.dart' as badges;
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notificationService = NotificationService();
  
  List<NotifikasiModel> _allNotifications = [];
  Map<String, dynamic> _unreadCounts = {
    'semua': 0, 'stok': 0, 'transaksi': 0, 'laporan': 0, 'sistem': 0, 'promo': 0
  };
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Tab types mapping
  final List<String> _tabTypes = ['semua', 'stok', 'transaksi', 'laporan', 'sistem'];
  final List<String> _tabLabels = ['Semua', 'Stok', 'Transaksi', 'Laporan', 'Sistem'];

  @override
  void initState() {
    super.initState();
    // Initialize timeago indonesian translation
    timeago.setLocaleMessages('id', timeago.IdMessages());
    
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadData(tipe: _tabTypes[_tabController.index], showLoading: false);
    }
  }

  Future<void> _loadData({String? tipe, bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    final activeTipe = tipe ?? _tabTypes[_tabController.index];
    final result = await _notificationService.getNotifications(tipe: activeTipe);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _allNotifications = result['notifications'] as List<NotifikasiModel>;
          _unreadCounts = Map<String, dynamic>.from(result['unread_counts']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    }
  }

  // --- Bulk Actions ---
  Future<void> _markAllAsRead() async {
    final response = await _notificationService.markAllAsRead();
    if (mounted && response['success'] == true) {
      _loadData(showLoading: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Semua notifikasi ditandai dibaca'),
          backgroundColor: const Color(0xFF8B5E3C),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: Colors.white,
            onPressed: () {
              // Mock undo logic: mark them as unread again (requires ID tracking)
              // In this case, we just refresh
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteConfirmDialog(),
    );

    if (result == true) {
      final response = await _notificationService.clearAllNotifications();
      if (mounted) {
        if (response['success'] == true) {
          _loadData(showLoading: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Semua notifikasi dihapus'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Show error (e.g., cannot delete urgent alert)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal menghapus'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- Single Item Actions ---
  Future<void> _toggleReadStatus(NotifikasiModel notif) async {
    final Map<String, dynamic> response;
    if (notif.sudahDibaca) {
      response = await _notificationService.markAsUnread(notif.id);
    } else {
      response = await _notificationService.markAsRead(notif.id);
    }

    if (mounted && response['success'] == true) {
      _loadData(showLoading: false);
    }
  }

  Future<void> _deleteNotification(NotifikasiModel notif) async {
    final response = await _notificationService.deleteNotification(notif.id);
    if (mounted) {
      if (response['success'] == true) {
        _loadData(showLoading: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Group notifications by date
  Map<String, List<NotifikasiModel>> _groupNotifications(List<NotifikasiModel> list) {
    final Map<String, List<NotifikasiModel>> groups = {
      '🔴 HARI INI': [],
      '🟡 KEMARIN': [],
      '⚪ MINGGU INI': [],
      '⚪ LEBIH LAMA': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (var notif in list) {
      final notifDate = DateTime(notif.waktu.year, notif.waktu.month, notif.waktu.day);
      if (notifDate.isAtSameMomentAs(today)) {
        groups['🔴 HARI INI']!.add(notif);
      } else if (notifDate.isAtSameMomentAs(yesterday)) {
        groups['🟡 KEMARIN']!.add(notif);
      } else if (notifDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        groups['⚪ MINGGU INI']!.add(notif);
      } else {
        groups['⚪ LEBIH LAMA']!.add(notif);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  void _showNotificationDetail(NotifikasiModel notif) {
    // Automatically mark as read if tapped
    if (!notif.sudahDibaca) {
      _toggleReadStatus(notif);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetailSheet(
        notification: notif,
        onAction: (targetTab) {
          Navigator.pop(context); // Close bottom sheet
          Navigator.pop(context, {'tab': targetTab}); // Return target tab to Dashboard
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteNotification(notif);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCounts['semua'] ?? 0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER SECTION
            _HeaderSection(
              unreadCount: unreadCount,
              onMarkAllRead: _markAllAsRead,
              onOpenSettings: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const _NotificationSettingPage()),
                ).then((_) => _loadData(showLoading: false));
              },
            ),
            
            // 2. FILTER TAB BAR (Sticky)
            _FilterTabBar(
              tabController: _tabController,
              labels: _tabLabels,
              unreadCounts: _unreadCounts,
              types: _tabTypes,
            ),
            
            // 3. ACTION BAR
            _ActionBar(
              unreadCount: unreadCount,
              onMarkAllRead: _markAllAsRead,
              onClearAll: _confirmDeleteAll,
            ),
            
            // 4. MAIN CONTENT AREA
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5E3C)),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadData(showLoading: false),
                          color: const Color(0xFF8B5E3C),
                          child: _allNotifications.isEmpty
                              ? _EmptyState(
                                  tabIndex: _tabController.index,
                                  onBack: () => Navigator.pop(context),
                                )
                              : ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 24),
                                  children: [
                                    // 5. SUMMARY BANNER (If there are unread critical alerts)
                                    _SummaryBanner(
                                      notifications: _allNotifications,
                                      onViewDetail: _showNotificationDetail,
                                    ),
                                    
                                    // 6. LIST OF NOTIFICATIONS GROUPED BY TIME
                                    ..._buildNotificationGroups(),
                                  ],
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNotificationGroups() {
    final grouped = _groupNotifications(_allNotifications);
    final List<Widget> widgets = [];

    grouped.forEach((timeGroup, items) {
      widgets.add(_NotificationGroupHeader(title: timeGroup));
      
      for (var item in items) {
        widgets.add(
          _NotificationCard(
            notification: item,
            onTap: () => _showNotificationDetail(item),
            onToggleRead: () => _toggleReadStatus(item),
            onDelete: () => _deleteNotification(item),
          ),
        );
      }
    });

    return widgets;
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: HEADER SECTION
// -------------------------------------------------------------
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8C6239), // Coklat keemasan medium
            Color(0xFF5C3A21), // Coklat keemasan tua
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unreadCount > 0 ? '($unreadCount belum dibaca)' : 'Semua dibaca',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                tooltip: 'Tandai Semua Dibaca',
                onPressed: onMarkAllRead,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Pengaturan Notifikasi',
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: FILTER TAB BAR (Pill Style)
// -------------------------------------------------------------
class _FilterTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<String> labels;
  final Map<String, dynamic> unreadCounts;
  final List<String> types;

  const _FilterTabBar({
    required this.tabController,
    required this.labels,
    required this.unreadCounts,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF8B5E3C),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: List.generate(labels.length, (index) {
          final count = unreadCounts[types[index]] ?? 0;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labels[index]),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

// -------------------------------------------------------------
// SUB-WIDGET: ACTION BAR
// -------------------------------------------------------------
class _ActionBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  const _ActionBar({
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$unreadCount notifikasi belum dibaca',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: onMarkAllRead,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Baca Semua',
                  style: TextStyle(
                    color: Color(0xFF8B5E3C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                ' | ',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

// -------------------------------------------------------------
// SUB-WIDGET: SUMMARY BANNER
// -------------------------------------------------------------
class _SummaryBanner extends StatefulWidget {
  final List<NotifikasiModel> notifications;
  final Function(NotifikasiModel) onViewDetail;

  const _SummaryBanner({
    required this.notifications,
    required this.onViewDetail,
  });

  @override
  State<_SummaryBanner> createState() => _SummaryBannerState();
}

class _SummaryBannerState extends State<_SummaryBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    // Look for unread urgent stock alerts or recent transactions
    final criticalAlerts = widget.notifications
        .where((n) => !n.sudahDibaca && (n.isUrgent || n.tipe == 'stok'))
        .toList();

    if (criticalAlerts.isEmpty) return const SizedBox.shrink();

    final mainAlert = criticalAlerts.first;
    final totalCount = criticalAlerts.length;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2), // Krem muda
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔴 $totalCount notifikasi perlu perhatian',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mainAlert.pesan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => widget.onViewDetail(mainAlert),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              backgroundColor: const Color(0xFF8B5E3C).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Lihat →',
              style: TextStyle(
                color: Color(0xFF8B5E3C),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: TIME GROUP HEADER
// -------------------------------------------------------------
class _NotificationGroupHeader extends StatelessWidget {
  final String title;

  const _NotificationGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5E6D3), // krem muda
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: NOTIFICATION CARD (Slidable)
// -------------------------------------------------------------
class _NotificationCard extends StatefulWidget {
  final NotifikasiModel notification;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onToggleRead,
    required this.onDelete,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.notification.isUrgent) {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Color _getTypeColor(String tipe) {
    switch (tipe) {
      case 'stok':
        return const Color(0xFFE53935); // merah
      case 'transaksi':
        return const Color(0xFF4CAF50); // hijau
      case 'laporan':
        return const Color(0xFF2196F3); // biru
      case 'sistem':
        return const Color(0xFF9E9E9E); // abu
      case 'promo':
        return const Color(0xFFD4A853); // emas
      default:
        return const Color(0xFF8B5E3C);
    }
  }

  IconData _getTypeIcon(String tipe) {
    switch (tipe) {
      case 'stok':
        return Icons.warning_rounded;
      case 'transaksi':
        return Icons.shopping_bag_rounded;
      case 'laporan':
        return Icons.analytics_rounded;
      case 'sistem':
        return Icons.info_rounded;
      case 'promo':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String tipe) {
    return tipe.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final primaryColor = _getTypeColor(notif.tipe);
    final iconData = _getTypeIcon(notif.tipe);
    
    // Background color
    Color cardBg;
    if (notif.isUrgent) {
      cardBg = const Color(0xFFFFEBEE); // Soft red background for urgent
    } else {
      cardBg = notif.sudahDibaca ? Colors.white : const Color(0xFFFFFDF8); // Krem sangat muda if unread
    }

    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: notif.isUrgent
            ? Border.all(color: const Color(0xFFE53935), width: 1.5)
            : Border(
                left: BorderSide(color: primaryColor, width: 3),
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(notif.sudahDibaca ? 0.02 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot indicator
                if (!notif.sudahDibaca)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3), // blue dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 16),
                
                // Icon in circle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge chip & Title
                          Flexible(
                            child: Row(
                              children: [
                                if (notif.isUrgent)
                                  _pulseController != null
                                      ? FadeTransition(
                                          opacity: _pulseController!,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935),
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
                                        )
                                      : const SizedBox.shrink()
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getTypeLabel(notif.tipe),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    notif.judul,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: notif.sudahDibaca ? FontWeight.w500 : FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Waktu
                          Text(
                            timeago.format(notif.waktu, locale: 'id'),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.pesan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      
                      // Action buttons inside card if they exist
                      if (_hasActionButton(notif)) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: widget.onTap, // Tap to open detail which also provides primary actions
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _getActionButtonLabel(notif),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Setup slidable actions
    return Slidable(
      key: Key(notif.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onToggleRead(),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon: notif.sudahDibaca ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
            label: notif.sudahDibaca ? 'Belum' : 'Baca',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Hapus',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: cardContent,
    );
  }

  bool _hasActionButton(NotifikasiModel notif) {
    if (notif.tipe == 'sistem') return false;
    return true;
  }

  String _getActionButtonLabel(NotifikasiModel notif) {
    switch (notif.tipe) {
      case 'stok':
        return 'Restock Sekarang';
      case 'transaksi':
        return 'Lihat Detail';
      case 'laporan':
        return 'Lihat Laporan';
      case 'promo':
        return 'Cek Sekarang';
      default:
        return 'Aksi';
    }
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: EMPTY STATE
// -------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onBack;

  const _EmptyState({
    required this.tabIndex,
    required this.onBack,
  });

  IconData _getEmptyIcon() {
    switch (tabIndex) {
      case 1: // Stok
        return Icons.inventory_2_outlined;
      case 2: // Transaksi
        return Icons.receipt_long_outlined;
      case 3: // Laporan
        return Icons.analytics_outlined;
      case 4: // Sistem
        return Icons.info_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _getEmptyTitle() {
    switch (tabIndex) {
      case 1: // Stok
        return 'Tidak Ada Peringatan Stok';
      case 2: // Transaksi
        return 'Belum Ada Notifikasi Transaksi';
      case 3: // Laporan
        return 'Belum Ada Laporan Tersedia';
      case 4: // Sistem
        return 'Tidak Ada Info Sistem';
      default:
        return 'Tidak Ada Notifikasi';
    }
  }

  String _getEmptySubtitle() {
    switch (tabIndex) {
      case 1: // Stok
        return 'Semua jumlah stok produk UMKM Abon Salakopi dalam kondisi aman.';
      case 2: // Transaksi
        return 'Transaksi penjualan yang Anda catat akan otomatis muncul di sini.';
      case 3: // Laporan
        return 'Laporan performa penjualan harian, mingguan, dan bulanan belum siap.';
      case 4: // Sistem
        return 'Pengumuman pemeliharaan atau info update aplikasi akan muncul di sini.';
      default:
        return 'Semua notifikasi penting terkait operasional usaha Anda akan terkumpul di sini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Lonceng Besar Bergoyang
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, val, child) {
              return Transform.rotate(
                angle: (1 - val) * 0.3,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyIcon(),
                size: 80,
                color: const Color(0xFF8B5E3C).withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyTitle(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C), // coklat bold
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getEmptySubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5E3C),
              side: const BorderSide(color: Color(0xFF8B5E3C), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kembali ke Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: DELETE CONFIRM DIALOG
// -------------------------------------------------------------
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Hapus Semua Notifikasi?',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: const Text(
        'Tindakan ini akan menghapus semua notifikasi permanen dan tidak dapat dibatalkan.',
        style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET: NOTIFICATION DETAIL BOTTOM SHEET
// -------------------------------------------------------------
class _NotificationDetailSheet extends StatelessWidget {
  final NotifikasiModel notification;
  final Function(int) onAction; // returns target tab index to navigate to
  final VoidCallback onDelete;

  const _NotificationDetailSheet({
    required this.notification,
    required this.onAction,
    required this.onDelete,
  });

  Color _getTypeColor(String tipe) {
    switch (tipe) {
      case 'stok':
        return const Color(0xFFE53935);
      case 'transaksi':
        return const Color(0xFF4CAF50);
      case 'laporan':
        return const Color(0xFF2196F3);
      case 'sistem':
        return const Color(0xFF9E9E9E);
      case 'promo':
        return const Color(0xFFD4A853);
      default:
        return const Color(0xFF8B5E3C);
    }
  }

  IconData _getTypeIcon(String tipe) {
    switch (tipe) {
      case 'stok':
        return Icons.warning_rounded;
      case 'transaksi':
        return Icons.shopping_bag_rounded;
      case 'laporan':
        return Icons.analytics_rounded;
      case 'sistem':
        return Icons.info_rounded;
      case 'promo':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = notification;
    final primaryColor = _getTypeColor(notif.tipe);
    final iconData = _getTypeIcon(notif.tipe);
    final formattedTime = _getFormattedTimeFull(notif.waktu);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          
          // HEADER: Big icon in circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          
          // Badge chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notif.tipe.toUpperCase(),
              style: TextStyle(
                color: primaryColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Title
          Text(
            notif.judul,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          
          // Time
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          
          // BODY: Full message content
          Text(
            notif.pesan,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          
          // Specific detailed structures
          if (notif.data != null) ...[
            const SizedBox(height: 16),
            _buildDetailedDataTable(notif.tipe, notif.data!),
          ],
          const SizedBox(height: 24),
          
          // ACTION BUTTONS
          if (_hasAction(notif.tipe)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Determine target tab to route inside main page
                  int targetTab = 0;
                  if (notif.tipe == 'stok') targetTab = 1;      // Inventaris
                  if (notif.tipe == 'transaksi') targetTab = 2; // Penjualan
                  if (notif.tipe == 'laporan') targetTab = 4;   // Laporan
                  onAction(targetTab);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _getActionBtnLabel(notif.tipe),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          
          // Delete option (unless urgent block)
          if (!(notif.isUrgent && notif.tipe == 'stok' && notif.data?['stock'] == 0)) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDelete,
              child: const Text(
                'Hapus Notifikasi Ini',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFormattedTimeFull(DateTime dt) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final dayName = days[dt.weekday % 7];
    final monthName = months[dt.month - 1];
    
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dayName, ${dt.day} $monthName ${dt.year} • $hour:$minute WIB';
  }

  bool _hasAction(String tipe) {
    return tipe != 'sistem';
  }

  String _getActionBtnLabel(String tipe) {
    switch (tipe) {
      case 'stok':
        return 'Buka Inventaris';
      case 'transaksi':
        return 'Lihat Transaksi';
      case 'laporan':
        return 'Buka Laporan Penjualan';
      case 'promo':
        return 'Pengecekan Sekarang';
      default:
        return 'Lanjutkan';
    }
  }

  Widget _buildDetailedDataTable(String tipe, Map<String, dynamic> data) {
    List<TableRow> rows = [];

    if (tipe == 'stok') {
      rows = [
        _buildDataRow('Nama Produk', data['product_name']?.toString() ?? '-'),
        _buildDataRow('Stok Saat Ini', '${data['stock'] ?? 0} pcs'),
        _buildDataRow('Batas Minimum', '${data['min_stock'] ?? 10} pcs'),
        _buildDataRow('Status', (data['stock'] ?? 0) == 0 ? 'HABIS' : 'KRITIS', color: const Color(0xFFE53935)),
      ];
    } else if (tipe == 'transaksi') {
      final int amount = data['amount'] ?? 0;
      rows = [
        _buildDataRow('ID Transaksi', data['transaction_id']?.toString() ?? '-'),
        _buildDataRow('Produk', '${data['product_name']} x${data['qty']}'),
        _buildDataRow('Total Nominal', 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
        _buildDataRow('Metode Bayar', data['payment_method']?.toString() ?? '-'),
      ];
    } else if (tipe == 'laporan') {
      final int revenue = data['revenue'] ?? 0;
      rows = [
        _buildDataRow('Periode Laporan', data['period']?.toString() ?? '-'),
        _buildDataRow('Tanggal Laporan', data['date']?.toString() ?? '-'),
        _buildDataRow('Total Penjualan', 'Rp ${revenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
        _buildDataRow('Jumlah Transaksi', '${data['transactions_count'] ?? 0} Transaksi'),
      ];
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.8),
        },
        children: rows,
      ),
    );
  }

  TableRow _buildDataRow(String label, String val, {Color? color}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// SUB-WIDGET / PAGE: NOTIFICATION SETTING PAGE
// -------------------------------------------------------------
class _NotificationSettingPage extends StatefulWidget {
  const _NotificationSettingPage();

  @override
  State<_NotificationSettingPage> createState() => _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<_NotificationSettingPage> {
  final _service = NotificationService();
  bool _isLoading = true;
  
  // Toggles
  bool _stokAlert = true;
  bool _transaksiAlert = true;
  bool _laporanAlert = true;
  bool _sistemAlert = true;
  bool _promoAlert = true;
  
  // Limit & Frekuensi
  double _stokLimit = 10;
  String _laporanFrekuensi = 'mingguan'; // harian|mingguan|bulanan

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final response = await _service.getSettings();
    if (mounted) {
      if (response['success'] == true) {
        final settings = response['settings'] as NotifikasiSettingModel;
        setState(() {
          _stokAlert = settings.stokAlert;
          _transaksiAlert = settings.transaksiAlert;
          _laporanAlert = settings.laporanAlert;
          _sistemAlert = settings.sistemAlert;
          _promoAlert = settings.promoAlert;
          _stokLimit = settings.stokLimit.toDouble();
          _laporanFrekuensi = settings.laporanFrekuensi;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengambil pengaturan'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    final newSettings = NotifikasiSettingModel(
      stokAlert: _stokAlert,
      transaksiAlert: _transaksiAlert,
      laporanAlert: _laporanAlert,
      sistemAlert: _sistemAlert,
      promoAlert: _promoAlert,
      stokLimit: _stokLimit.toInt(),
      laporanFrekuensi: _laporanFrekuensi,
    );

    final response = await _service.updateSettings(newSettings);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pengaturan notifikasi berhasil disimpan'),
            backgroundColor: Color(0xFF8B5E3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal menyimpan'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Color(0xFF8B5E3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5E3C)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                const Text(
                  'PREFERENCE TOGGLES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildToggleCard(
                  title: 'Peringatan Stok',
                  subtitle: 'Notif saat stok menipis atau habis',
                  value: _stokAlert,
                  onChanged: (val) => setState(() => _stokAlert = val),
                  color: const Color(0xFFE53935),
                ),
                _buildToggleCard(
                  title: 'Konfirmasi Transaksi',
                  subtitle: 'Notif setiap transaksi baru berhasil dicatat',
                  value: _transaksiAlert,
                  onChanged: (val) => setState(() => _transaksiAlert = val),
                  color: const Color(0xFF4CAF50),
                ),
                _buildToggleCard(
                  title: 'Laporan Siap',
                  subtitle: 'Notif saat laporan performa UMKM tersedia',
                  value: _laporanAlert,
                  onChanged: (val) => setState(() => _laporanAlert = val),
                  color: const Color(0xFF2196F3),
                ),
                _buildToggleCard(
                  title: 'Info Sistem',
                  subtitle: 'Update, pemeliharaan & pengumuman aplikasi',
                  value: _sistemAlert,
                  onChanged: (val) => setState(() => _sistemAlert = val),
                  color: const Color(0xFF9E9E9E),
                ),
                _buildToggleCard(
                  title: 'Pengingat & Promo',
                  subtitle: 'Tips berkala, event, dan rekomendasi program',
                  value: _promoAlert,
                  onChanged: (val) => setState(() => _promoAlert = val),
                  color: const Color(0xFFD4A853),
                ),
                
                const SizedBox(height: 28),
                const Text(
                  'BATAS STOK MENIPIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Beri tahu saat stok ≤',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_stokLimit.toInt()} pcs',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5E3C),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _stokLimit,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          activeColor: const Color(0xFF8B5E3C),
                          inactiveColor: const Color(0xFFF5E6D3),
                          onChanged: _stokAlert
                              ? (val) {
                                  setState(() {
                                    _stokLimit = val;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          'Sistem akan otomatis mengirimkan notifikasi stok kritis jika kuantitas produk Anda menyentuh batas di atas.',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                const Text(
                  'FREKUENSI LAPORAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildRadioTile('Harian (setiap jam 20.00)', 'harian'),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildRadioTile('Mingguan (setiap hari Senin)', 'mingguan'),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildRadioTile('Bulanan (setiap tanggal 1)', 'bulanan'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFF8B5E3C),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _laporanFrekuensi,
      activeColor: const Color(0xFF8B5E3C),
      onChanged: _laporanAlert
          ? (val) {
              setState(() {
                _laporanFrekuensi = val ?? 'mingguan';
              });
            }
          : null,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
