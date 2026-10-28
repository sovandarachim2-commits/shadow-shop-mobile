import 'package:flutter/foundation.dart';

import '../models/cart_line.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/shop_service.dart';

class ShopState extends ChangeNotifier {
  ShopState(this.api) : service = ShopService(api);

  final ApiClient api;
  final ShopService service;
  final Map<String, CartLine> _cart = {};
  Map<String, dynamic>? user;
  bool busy = false;
  String? error;
  final Set<int> wishlistIds = {};
  List<Map<String, dynamic>> savedAddresses = [];
  String couponCode = '';
  int get itemCount =>
      _cart.values.fold(0, (total, line) => total + line.quantity);
  double get subtotal =>
      _cart.values.fold(0, (total, line) => total + line.total);
  List<CartLine> get cartLines => _cart.values.toList(growable: false);

  bool sessionChecked = false;

  Future<void> restoreSession() async {
    if (!await api.hasToken()) {
      sessionChecked = true;
      notifyListeners();
      return;
    }
    try {
      user = await service.currentUser();
      if (user?['role'] != 'customer') await logout();
    } catch (_) {
      await logout();
    }
    if (user != null) {
      try {
        await loadWishlist();
      } catch (_) {}
      try {
        await loadAddresses();
      } catch (_) {}
    }
    sessionChecked = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await service.login(username, password);
      return true;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await api.clearTokens();
    user = null;
    _cart.clear();
    couponCode = '';
    wishlistIds.clear();
    savedAddresses = [];
    notifyListeners();
  }

  void add(Product product) {
    final current = _cart[product.cartKey]?.quantity ?? 0;
    if (!product.canAddMore(current)) return;
    setQuantity(product, current + 1);
  }

  Future<void> setQuantity(Product product, int quantity) async {
    if (quantity <= 0) {
      _cart.remove(product.cartKey);
    } else {
      final limit = product.maxOrderQuantity;
      if (limit == 0) {
        _cart.remove(product.cartKey);
      } else {
        _cart[product.cartKey] = CartLine(
          product: product,
          quantity: limit == null || quantity <= limit ? quantity : limit,
        );
      }
    }
    notifyListeners();
    if (user != null && !product.isProductSet) {
      try {
        await service.syncCart(product.id, quantity);
      } catch (_) {
        // Keep the local cart usable if the remote cart request fails.
      }
    }
  }

  Future<void> loadWishlist() async {
    final rows = await service.wishlist();
    wishlistIds
      ..clear()
      ..addAll(rows.map((row) => int.tryParse('${row['product']}') ?? 0));
    notifyListeners();
  }

  Future<void> toggleWishlist(Product product) async {
    final wasSaved = wishlistIds.contains(product.id);
    if (wasSaved) {
      wishlistIds.remove(product.id);
    } else {
      wishlistIds.add(product.id);
    }
    notifyListeners();
    try {
      await service.toggleWishlist(product.id, wasSaved);
    } catch (_) {
      if (wasSaved) {
        wishlistIds.add(product.id);
      } else {
        wishlistIds.remove(product.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadAddresses() async {
    savedAddresses = await service.addresses();
    notifyListeners();
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    await service.saveAddress(address);
    await loadAddresses();
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    user = await service.updateProfile(payload);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    couponCode = '';
    notifyListeners();
  }

  static String _message(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  Future<bool> loginWithGoogle(String idToken) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await service.loginWithGoogle(idToken);
      return true;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithTelegram(Map<String, dynamic> authData) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await service.loginWithTelegram(authData);
      return true;
    } catch (e) {
      error = _message(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
