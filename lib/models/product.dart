class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.categoryName = '',
    this.brandName = '',
    this.available = true,
    this.stock = 0,
    this.description = '',
    this.oldPrice,
    this.rating = 0,
    this.isFlashSale = false,
    this.productSetId,
    this.isProductSet = false,
  });

  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final String categoryName;
  final String brandName;
  final bool available;
  final int stock;
  final String description;
  final double? oldPrice;
  final double rating;
  final bool isFlashSale;
  final int? productSetId;
  final bool isProductSet;

  String get cartKey =>
      isProductSet ? 'set_${productSetId ?? id}' : 'product_$id';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: _asInt(json['id']),
        name: (json['name'] ?? '').toString(),
        price: _asDouble(json['display_price'] ?? json['retail_price']),
        imageUrl: _asNullableString(json['primary_image']),
        categoryName: (json['category_name'] ?? '').toString(),
        brandName: (json['brand_name'] ?? '').toString(),
        available: json['is_available_for_sale'] != false,
        stock: _asInt(json['current_stock']),
        description: (json['description'] ?? '').toString(),
        oldPrice:
            json['old_price'] == null ? null : _asDouble(json['old_price']),
        rating: _asDouble(json['rating']),
        isFlashSale: json['is_flash_sale_active'] == true,
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String? _asNullableString(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();
