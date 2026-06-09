import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'package:intl/intl.dart';

class InventarisPage extends StatefulWidget {
  const InventarisPage({super.key});

  @override
  State<InventarisPage> createState() => _InventarisPageState();
}

class _InventarisPageState extends State<InventarisPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  
  // Track adjusting states per product to show individual loading spinners
  final Map<int, bool> _adjustingProductIds = {};

  final List<String> _categories = ['Semua', 'Abon Sapi', 'Abon Ayam', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final response = await _productService.getProducts();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        setState(() {
          _allProducts = response['products'] as List<ProductModel>;
          _applyFilters();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengambil data produk'),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilters();
    });
  }

  String _getProductCategory(ProductModel product) {
    final nameLower = product.name.toLowerCase();
    if (nameLower.contains('sapi')) {
      return 'Abon Sapi';
    } else if (nameLower.contains('ayam')) {
      return 'Abon Ayam';
    }
    return 'Lainnya';
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Search query filter
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
            product.sku.toLowerCase().contains(_searchQuery);
        
        // Category filter
        if (_selectedCategory == 'Semua') {
          return matchesSearch;
        } else {
          return matchesSearch && _getProductCategory(product) == _selectedCategory;
        }
      }).toList();
    });
  }

  Future<void> _adjustStock(ProductModel product, String type) async {
    if (type == 'out' && product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok sudah habis, tidak bisa dikurangi lagi.'),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _adjustingProductIds[product.id] = true;
    });

    final response = await _productService.adjustStock(
      productId: product.id,
      type: type,
      quantity: 1,
      reason: type == 'in' ? 'Tambah Stok Cepat' : 'Kurang Stok Cepat',
    );

    if (mounted) {
      setState(() {
        _adjustingProductIds[product.id] = false;
      });

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok ${product.name} berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memperbarui stok'),
            backgroundColor: AppColors.alert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStockBadge(ProductModel product) {
    Color badgeColor;
    String label;
    
    if (product.stock == 0) {
      badgeColor = AppColors.alert;
      label = 'Stok Habis';
    } else if (product.stock <= product.minStock) {
      badgeColor = AppColors.warning;
      label = 'Stok Menipis';
    } else {
      badgeColor = AppColors.success;
      label = 'Stok Aman';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventaris Gudang', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProducts,
          )
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk atau SKU...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textGrey),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Categories Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isAdjusting = _adjustingProductIds[product.id] ?? false;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200, width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Product Box Icon / Avatar
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.rice_bowl_rounded,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${product.sku}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              currencyFormat.format(product.price),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Text(' / ', style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
                                            Text(
                                              product.unit,
                                              style: const TextStyle(
                                                color: AppColors.textGrey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _buildStockBadge(product),
                                      ],
                                    ),
                                  ),

                                  // Quick stock adjuster (+/- buttons)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 22),
                                          onPressed: isAdjusting ? null : () => _adjustStock(product, 'out'),
                                        ),
                                        isAdjusting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                ),
                                              )
                                            : Text(
                                                '${product.stock}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                                          onPressed: isAdjusting ? null : () => _adjustStock(product, 'in'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Produk Tidak Ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada produk yang cocok dengan pencarian atau filter kategori Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
