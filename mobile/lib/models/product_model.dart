class ProductModel {
  final int id;
  final String name;
  final String sku;
  final String? description;
  final int price;
  final int stock;
  final int minStock;
  final String unit;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String?,
      price: json['price'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      minStock: json['min_stock'] as int? ?? 5,
      unit: json['unit'] as String? ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'unit': unit,
    };
  }
}
