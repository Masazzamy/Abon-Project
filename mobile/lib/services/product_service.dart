import '../api/api_client.dart';
import '../models/product_model.dart';

class ProductService {
  /// Fetch all products from the backend Laravel server.
  Future<Map<String, dynamic>> getProducts({bool lowStock = false}) async {
    final endpoint = lowStock ? 'products?low_stock=true' : 'products';
    final response = await ApiClient.get(endpoint);

    if (response['success'] == true) {
      final List<dynamic> listJson = response['data'] ?? [];
      final List<ProductModel> products = listJson
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
          
      return {
        'success': true,
        'products': products,
        'message': response['message'] ?? 'Produk berhasil diambil',
      };
    } else {
      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil daftar produk',
        'isOffline': response['isOffline'] == true,
      };
    }
  }
}
