class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.categoryName = '',
    this.brandName = '',
    this.available = true,
    this.stock = 0,
    this.availabilityStatus = 'auto',
    this.description = '',
    this.oldPrice,
    this.rating = 0,
    this.isFlashSale = false,
    this.flashSaleMaxOrderQty,
    this.productSetId,
    this.isProductSet = false,
  });

  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final int? categoryId;
  final String categoryName;
  final String brandName;
  final bool available;
  final int stock;
  final String availabilityStatus;
  final String description;
  final double? oldPrice;
  final double rating;
  final bool isFlashSale;
  final int? flashSaleMaxOrderQty;
  final int? productSetId;
  final bool isProductSet;

  int? get maxOrderQuantity {
    if (!available || availabilityStatus == 'out_of_stock') return 0;

    final stockLimit = availabilityStatus == 'available' ? null : stock;
    final saleLimit = isFlashSale && (flashSaleMaxOrderQty ?? 0) > 0
        ? flashSaleMaxOrderQty
        : null;

    if (stockLimit == null) return saleLimit;
    if (saleLimit == null) return stockLimit;
    return stockLimit < saleLimit ? stockLimit : saleLimit;
  }

  bool canAddMore(int quantityInCart) {
    final limit = maxOrderQuantity;
    return available && (limit == null || quantityInCart < limit);
  }

  String get cartKey =>
      isProductSet ? 'set_${productSetId ?? id}' : 'product_$id';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: _asInt(json['id']),
        name: (json['name'] ?? '').toString(),
        price: _asDouble(json['display_price'] ?? json['retail_price']),
        imageUrl: _asNullableString(json['primary_image']),
        categoryId: json['category'] == null ? null : _asInt(json['category']),
        categoryName: (json['category_name'] ?? '').toString(),
        brandName: (json['brand_name'] ?? '').toString(),
        available: json['is_available_for_sale'] != false,
        stock: _asInt(json['current_stock']),
        availabilityStatus: (json['availability_status'] ?? 'auto').toString(),
        description: (json['description'] ?? '').toString(),
        oldPrice:
            json['old_price'] == null ? null : _asDouble(json['old_price']),
        rating: _asDouble(json['rating']),
        isFlashSale: json['is_flash_sale_active'] == true,
        flashSaleMaxOrderQty: json['flash_sale_max_order_qty'] == null
            ? null
            : _asInt(json['flash_sale_max_order_qty']),
      );
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String? _asNullableString(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();
