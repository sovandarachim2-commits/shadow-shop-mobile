import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/')) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.endsWith('auth/login/') &&
              !error.requestOptions.path.endsWith('auth/refresh/')) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retry = error.requestOptions;
              final token = await storage.read(key: accessTokenKey);
              retry.headers['Authorization'] = 'Bearer $token';
              try {
                handler.resolve(await dio.fetch(retry));
                return;
              } catch (_) {
                await clearTokens();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static const accessTokenKey = 'shadow_shop_access_token';
  static const refreshTokenKey = 'shadow_shop_refresh_token';
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  final Dio dio;

  Future<bool> _refreshToken() async {
    final refresh = await storage.read(key: refreshTokenKey);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response =
          await Dio(BaseOptions(baseUrl: '${AppConfig.apiBaseUrl}/')).post(
        'auth/refresh/',
        data: {'refresh': refresh},
      );
      final access = response.data['access']?.toString();
      final nextRefresh = response.data['refresh']?.toString() ?? refresh;
      if (access == null || access.isEmpty) return false;
      await storage.write(key: accessTokenKey, value: access);
      await storage.write(key: refreshTokenKey, value: nextRefresh);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Future<void> saveTokens(Map<String, dynamic> data) async {
    await storage.write(key: accessTokenKey, value: data['access']?.toString());
    await storage.write(
      key: refreshTokenKey,
      value: data['refresh']?.toString(),
    );
  }

  Future<bool> hasToken() async =>
      (await storage.read(key: accessTokenKey))?.isNotEmpty == true;

  Future<void> clearTokens() async {
    await storage.delete(key: accessTokenKey);
    await storage.delete(key: refreshTokenKey);
  }
}
