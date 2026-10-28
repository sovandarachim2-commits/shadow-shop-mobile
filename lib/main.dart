import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/app/app.dart';
import 'package:shadow_shop_mobile/services/api_client.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
    create: (_) => ShopState(ApiClient())..restoreSession(),
    child: const ShadowShopApp(),
  ));
}
