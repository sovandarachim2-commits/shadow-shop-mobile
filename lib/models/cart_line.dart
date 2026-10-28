import 'product.dart';

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;
  String get cartKey => product.cartKey;

  double get total => product.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}
