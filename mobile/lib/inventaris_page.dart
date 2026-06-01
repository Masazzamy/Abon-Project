import 'package:flutter/material.dart';
import 'app_colors.dart';

class InventarisPage extends StatefulWidget {
  const InventarisPage({super.key});

  @override
  State<InventarisPage> createState() => _InventarisPageState();
}

class _InventarisPageState extends State<InventarisPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _produkList = [];
  
  // For Undo Delete functionality
  Map<String, dynamic>? _lastDeletedProduct;
  int? _lastDeletedIndex;

  String _searchQuery = "";
  String _selectedFilter = "Semua"; // Semua, Stok Aman, Stok Menipis, Habis
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Simulate initial load with a shimmer effect
    _triggerShimmer();
  }

  void _triggerShimmer() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Add or edit product
  void _saveProduct(Map<String, dynamic> productData, {int? index}) {
    setState(() {
      _isLoading = true;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (index != null) {
            _produkList[index] = productData;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Produk "${productData['nama']}" berhasil diperbarui!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            _produkList.add(productData);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Produk "${productData['nama']}" berhasil ditambahkan!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _isLoading = false;
        });
      }
    });
  }

  // Delete product with Undo
  void _deleteProduct(int index) {
    final deletedProduct = _produkList[index];
    setState(() {
      _lastDeletedProduct = deletedProduct;
      _lastDeletedIndex = index;
      _produkList.removeAt(index);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${deletedProduct['nama']}" dihapus'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppColors.accent,
          onPressed: () {
            if (_lastDeletedProduct != null && _lastDeletedIndex != null) {
              setState(() {
                _produkList.insert(_lastDeletedIndex!, _lastDeletedProduct!);
              });
            }
          },
        ),
      ),
    );
  }

  // Open Bottom Sheet Form
  void _openAddEditBottomSheet({Map<String, dynamic>? productToEdit, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductBottomSheet(
        productToEdit: productToEdit,
        onSave: (data) => _saveProduct(data, index: index),
      ),
    );
  }

  // Filter and Search logic
  List<Map<String, dynamic>> get _filteredProducts {
    return _produkList.where((p) {
      final matchesSearch = p['nama'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p['kategori'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final int stok = p['stok'] ?? 0;
      bool matchesFilter = false;

      if (_selectedFilter == "Semua") {
        matchesFilter = true;
      } else if (_selectedFilter == "Stok Aman") {
        matchesFilter = stok > 10;
      } else if (_selectedFilter == "Stok Menipis") {
        matchesFilter = stok >= 1 && stok <= 10;
      } else if (_selectedFilter == "Habis") {
        matchesFilter = stok == 0;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Summary counts
  int get _totalProductCount => _produkList.length;
  int get _safeStockCount => _produkList.where((p) => (p['stok'] ?? 0) > 10).length;
  int get _warningStockCount => _produkList.where((p) => (p['stok'] ?? 0) >= 0 && (p['stok'] ?? 0) <= 10).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. HEADER SECTION (SliverAppBar)
            _HeaderSection(
              onAddPressed: () => _openAddEditBottomSheet(),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // 2. SUMMARY MINI CARDS (Horizontal Scroll)
                  _SummaryCards(
                    total: _totalProductCount,
                    safe: _safeStockCount,
                    warning: _warningStockCount,
                  ),
                  
                  const SizedBox(height: 20),

                  // 3. SEARCH & FILTER BAR
                  _SearchFilterBar(
                    selectedFilter: _selectedFilter,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                        _triggerShimmer();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // 4. LIST PRODUK (Empty state / loading / items)
            _isLoading
                ? const _ShimmerList()
                : _filteredProducts.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          isFiltering: _selectedFilter != "Semua" || _searchQuery.isNotEmpty,
                          onAddPressed: () => _openAddEditBottomSheet(),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _filteredProducts[index];
                              // Find actual index in original list for editing
                              final originalIndex = _produkList.indexOf(item);
                              
                              return _SwipeDismissibleCard(
                                key: ValueKey(item['nama'] + index.toString()),
                                product: item,
                                onDismissed: () => _deleteProduct(originalIndex),
                                onEdit: () => _openAddEditBottomSheet(productToEdit: item, index: originalIndex),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _ProductDetailPage(product: item),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _filteredProducts.length,
                          ),
                        ),
                      ),
            
            // Extra padding at bottom for FAB spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            )
          ],
        ),
      ),

      // 6. FAB (Floating Action Button) with Bounce Scale Animation
      floatingActionButton: _BounceFAB(
        onPressed: () => _openAddEditBottomSheet(),
      ),
    );
  }
}

// =========================================================================
// 1. HEADER SECTION WIDGET (Beautiful Golden Brown Gradient)
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
              colors: [
                AppColors.primary,
                Color(0xFFB37B50),
              ],
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
                    'Inventaris',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola stok produk Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              // Tambah Produk pill button
              ElevatedButton.icon(
                onPressed: onAddPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(120, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const StadiumBorder(),
                  elevation: 4,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
// 2. SUMMARY MINI CARDS WIDGET (Horizontal Scroll, 3 Cards)
// =========================================================================
class _SummaryCards extends StatelessWidget {
  final int total;
  final int safe;
  final int warning;

  const _SummaryCards({
    required this.total,
    required this.safe,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildCard(
            title: "Total Produk",
            value: total.toString(),
            icon: Icons.inventory_2_rounded,
            borderColor: AppColors.primary.withOpacity(0.3),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildCard(
            title: "Stok Aman",
            value: safe.toString(),
            icon: Icons.check_circle_rounded,
            borderColor: AppColors.success.withOpacity(0.3),
            iconColor: AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildCard(
            title: "Stok Menipis",
            value: warning.toString(),
            icon: Icons.warning_rounded,
            borderColor: AppColors.alert.withOpacity(0.3),
            iconColor: AppColors.alert,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. SEARCH & FILTER BAR WIDGET (Clean layout with chip sliding animation)
// =========================================================================
class _SearchFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const _SearchFilterBar({
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ["Semua", "Stok Aman", "Stok Menipis", "Habis"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search text field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Cari produk abon...",
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal filter chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isActive = selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: isActive,
                    onSelected: (selected) {
                      if (selected) {
                        onFilterChanged(filter);
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isActive ? Colors.transparent : AppColors.primary.withOpacity(0.5),
                      width: 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 4. EMPTY STATE WIDGET
// =========================================================================
class _EmptyState extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback onAddPressed;

  const _EmptyState({
    required this.isFiltering,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant big icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Main Header Text
          Text(
            isFiltering ? 'Produk Tidak Ditemukan' : 'Belum Ada Produk',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description Text
          Text(
            isFiltering
                ? 'Coba ganti filter Anda atau cari kata kunci lain.'
                : 'Tambahkan produk pertama Anda dengan menekan tombol + di atas',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // CTA Button
          if (!isFiltering)
            ElevatedButton.icon(
              onPressed: onAddPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(200, 50),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Produk Pertama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

// =========================================================================
// 5. PRODUCT CARD WIDGET WITH SWIPE DISMISSIBLE
// =========================================================================
class _SwipeDismissibleCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDismissed;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _SwipeDismissibleCard({
    super.key,
    required this.product,
    required this.onDismissed,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.alert.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
            SizedBox(height: 4),
            Text(
              "Hapus",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            )
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: _ProductCard(
        product: product,
        onEdit: onEdit,
        onTap: onTap,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int stok = product['stok'] ?? 0;
    
    // Status Stock Badge setup
    Color badgeColor;
    String badgeLabel;
    if (stok > 10) {
      badgeColor = AppColors.success;
      badgeLabel = "Stok Aman";
    } else if (stok >= 1) {
      badgeColor = AppColors.warning;
      badgeLabel = "Stok Menipis";
    } else {
      badgeColor = AppColors.alert;
      badgeLabel = "Habis";
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.04),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image / Icon representation (Hero animated)
              Hero(
                tag: 'product-img-${product['nama']}',
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.dining_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Product Info details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['kategori'] ?? 'Abon',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Product Name
                    Text(
                      product['nama'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Selling Price
                    Text(
                      'Rp ${product['hargaJual']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Actions and Stock Badge column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Stock Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$stok $badgeLabel',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
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
// 6. FAB BOUNCING EXTENDED WIDGET
// =========================================================================
class _BounceFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _BounceFAB({required this.onPressed});

  @override
  State<_BounceFAB> createState() => _BounceFABState();
}

class _BounceFABState extends State<_BounceFAB> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton.extended(
          onPressed: null, // Handled by gesture detector
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Tambah Produk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 7. BOTTOM SHEET FORM WIDGET FOR ADDING/EDITING PRODUCT
// =========================================================================
class _AddProductBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _AddProductBottomSheet({
    this.productToEdit,
    required this.onSave,
  });

  @override
  State<_AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends State<_AddProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _namaController;
  late final TextEditingController _hargaJualController;
  late final TextEditingController _hargaModalController;
  late final TextEditingController _stokController;
  late final TextEditingController _deskripsiController;
  
  String _selectedKategori = 'Abon';
  String _selectedSatuan = 'pcs';

  final List<String> _kategoriList = ['Abon', 'Daging', 'Camilan', 'Bumbu', 'Lainnya'];
  final List<String> _satuanList = ['pcs', 'gram', 'kg', 'box', 'pack'];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    
    _namaController = TextEditingController(text: p?['nama'] ?? '');
    _hargaJualController = TextEditingController(text: p?['hargaJual']?.toString() ?? '');
    _hargaModalController = TextEditingController(text: p?['hargaModal']?.toString() ?? '');
    _stokController = TextEditingController(text: p?['stok']?.toString() ?? '');
    _deskripsiController = TextEditingController(text: p?['deskripsi'] ?? '');
    
    if (p != null) {
      if (_kategoriList.contains(p['kategori'])) {
        _selectedKategori = p['kategori'];
      }
      if (_satuanList.contains(p['satuan'])) {
        _selectedSatuan = p['satuan'];
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaJualController.dispose();
    _hargaModalController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final productData = {
        'nama': _namaController.text.trim(),
        'kategori': _selectedKategori,
        'hargaJual': int.parse(_hargaJualController.text.trim()),
        'hargaModal': int.parse(_hargaModalController.text.trim()),
        'stok': int.parse(_stokController.text.trim()),
        'satuan': _selectedSatuan,
        'deskripsi': _deskripsiController.text.trim(),
      };
      
      widget.onSave(productData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header title
              Text(
                widget.productToEdit != null ? 'Edit Produk' : 'Tambah Produk Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Nama Produk Field
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama produk tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Row for Kategori and Satuan dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedKategori,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _kategoriList.map((kat) {
                        return DropdownMenuItem(value: kat, child: Text(kat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedKategori = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSatuan,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        prefixIcon: Icon(Icons.scale_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _satuanList.map((sat) {
                        return DropdownMenuItem(value: sat, child: Text(sat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSatuan = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row for Harga Modal and Harga Jual
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaModalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Modal (Rp)',
                        prefixIcon: Icon(Icons.money_off_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Kosong';
                        if (int.tryParse(val) == null) return 'Angka';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual (Rp)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Kosong';
                        if (int.tryParse(val) == null) return 'Angka';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stok Awal Field
              TextFormField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                  prefixIcon: Icon(Icons.production_quantity_limits_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Stok awal tidak boleh kosong';
                  if (int.tryParse(val) == null || int.parse(val) < 0) return 'Stok tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deskripsi (Optional)
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Produk (Opsional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _submitForm,
                      child: const Text('Simpan Produk'),
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
// CUSTOM SHIMMER LIST EFFECT (Pulsing Widget built using Flutter standard animation)
// =========================================================================
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _animation,
              child: Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 140,
                              height: 16,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.grey[200],
                            ),
                          ],
                        ),
                      ),
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
// PRODUCT DETAIL PAGE (with Hero Animation & Premium look)
// =========================================================================
class _ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    final int stok = product['stok'] ?? 0;
    final int hargaJual = product['hargaJual'] ?? 0;
    final int hargaModal = product['hargaModal'] ?? 0;
    final int margin = hargaJual - hargaModal;
    final double marginPercent = hargaModal > 0 ? (margin / hargaModal) * 100 : 0.0;

    Color badgeColor;
    String badgeLabel;
    if (stok > 10) {
      badgeColor = AppColors.success;
      badgeLabel = "Stok Aman";
    } else if (stok >= 1) {
      badgeColor = AppColors.warning;
      badgeLabel = "Stok Menipis";
    } else {
      badgeColor = AppColors.alert;
      badgeLabel = "Habis";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Produk',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image display
            Center(
              child: Hero(
                tag: 'product-img-${product['nama']}',
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.dining_rounded,
                      color: AppColors.primary,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Product Name and Category Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product['kategori'] ?? 'Abon',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product['nama'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Detailed specification grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow("Sisa Stok", "$stok ${product['satuan']}", valueColor: badgeColor, badgeColor: badgeColor.withOpacity(0.1)),
                  const Divider(),
                  _buildDetailRow("Harga Jual", "Rp $hargaJual", isBold: true),
                  const Divider(),
                  _buildDetailRow("Harga Modal", "Rp $hargaModal"),
                  const Divider(),
                  _buildDetailRow("Keuntungan / Margin", "Rp $margin (${marginPercent.toStringAsFixed(1)}%)", valueColor: AppColors.success),
                  const Divider(),
                  _buildDetailRow("Status", badgeLabel, valueColor: badgeColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Deskripsi Produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['deskripsi'] != null && product['deskripsi'].toString().isNotEmpty
                  ? product['deskripsi']
                  : 'Tidak ada deskripsi produk.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Action request restock
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permintaan restock untuk "${product['nama']}" berhasil dikirim!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Ajukan Restock'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, Color? badgeColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          badgeColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold || valueColor != null ? FontWeight.bold : FontWeight.normal,
                    color: valueColor ?? const Color(0xFF2C2C2C),
                  ),
                ),
        ],
      ),
    );
  }
}
