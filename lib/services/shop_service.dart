import 'package:dio/dio.dart';

import '../models/product.dart';
import 'api_client.dart';

class ShopService {
  const ShopService(this.api);

  final ApiClient api;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await api.dio.post(
      'auth/login/',
      data: {'username': username.trim(), 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if ((data['user'] as Map?)?['role'] != 'customer') {
      await api.clearTokens();
      throw Exception('This app is for customer accounts.');
    }
    await api.saveTokens(data);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> currentUser() async {
    final response = await api.dio.get('auth/me/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await api.dio.post('auth/register/', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> addresses() async =>
      _rows(await api.dio.get('auth/addresses/'));

  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> payload) async {
    final response = await api.dio.post('auth/addresses/', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> payload) async {
    final response = await api.dio.patch('auth/me/', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> wishlist() async =>
      _rows(await api.dio.get('orders/wishlist/'));

  Future<void> toggleWishlist(int productId, bool isSaved) async {
    final rows = await wishlist();
    final existing = rows
        .where((item) => int.tryParse('${item['product']}') == productId)
        .firstOrNull;
    if (isSaved && existing != null) {
      await api.dio.delete('orders/wishlist/${existing['id']}/');
    } else if (!isSaved && existing == null) {
      await api.dio.post('orders/wishlist/', data: {'product': productId});
    }
  }

  Future<Map<String, dynamic>> rewards() async {
    final response = await api.dio.get('orders/rewards/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> siteSettings() async {
    final response = await api.dio.get('auth/site-settings/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> confirmRegistration(String email, String code) async {
    await api.dio
        .post('auth/email/verify-code/', data: {'email': email, 'code': code});
  }

  Future<Map<String, dynamic>> verifyOrder(String reference,
      {String? statusToken}) async {
    final response = await api.dio.get(
      'orders/list/checkout_status/',
      queryParameters: {'reference': reference},
      options: Options(headers: {
        if (statusToken != null) 'X-Checkout-Status-Token': statusToken
      }),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> checkIn() async {
    final response = await api.dio.post('orders/rewards/daily_checkin/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> exchangeReward(int rewardId) async {
    final response = await api.dio
        .post('orders/rewards/exchange/', data: {'reward_item': rewardId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> payload) async {
    final response = await api.dio.post('orders/list/checkout/', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Product>> products({String search = ''}) async {
    final response = await api.dio.get(
      'products/items/',
      queryParameters: {
        'is_active': true,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _rows(response)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> homeFeed() async {
    final response = await api.dio.get('products/home/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> productSets({String search = ''}) async {
    final response = await api.dio.get('products/sets/', queryParameters: {
      'is_active': true,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    return _rows(response);
  }

  Future<Map<String, dynamic>> productDetail(int id) async {
    final response = await api.dio.get('products/items/$id/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> pointsHistory() async =>
      _rows(await api.dio.get('orders/rewards/history/'));

  Future<Map<String, dynamic>> validateCoupon(
      String code, double subtotal, double deliveryFee) async {
    final response =
        await api.dio.post('orders/rewards/validate_coupon/', data: {
      'coupon_code': code,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final response = await api.dio.get(
      'products/categories/',
      queryParameters: {'is_active': true},
    );
    return _rows(response);
  }

  Future<List<Map<String, dynamic>>> myOrders() async {
    final response = await api.dio.get(
      'orders/list/',
      queryParameters: {'my_orders': 1},
    );
    return _rows(response);
  }

  Future<Map<String, dynamic>> orderDetail(int id) async {
    final response = await api.dio
        .get('orders/list/$id/', queryParameters: {'my_orders': 1});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> syncCart(int productId, int quantity) async {
    final response = await api.dio.get('orders/cart/');
    final data = response.data;
    final rows =
        data is List ? data : (data as Map)['results'] as List? ?? const [];
    Map<String, dynamic>? match;
    for (final row in rows) {
      final item = Map<String, dynamic>.from(row as Map);
      if (int.tryParse('${item['product']}') == productId) match = item;
    }
    if (quantity <= 0 && match != null) {
      await api.dio.delete('orders/cart/${match['id']}/');
    } else if (match != null) {
      await api.dio.patch(
        'orders/cart/${match['id']}/',
        data: {'quantity': quantity},
      );
    } else if (quantity > 0) {
      await api.dio.post(
        'orders/cart/',
        data: {'product': productId, 'quantity': quantity},
      );
    }
  }

  List<Map<String, dynamic>> _rows(Response<dynamic> response) {
    final data = response.data;
    final rows =
        data is List ? data : (data as Map)['results'] as List? ?? const [];
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}
