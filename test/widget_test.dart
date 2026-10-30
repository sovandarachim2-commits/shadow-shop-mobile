import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/app/app.dart';
import 'package:shadow_shop_mobile/services/api_client.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ShopState(ApiClient()),
        child: const ShadowShopApp(),
      ),
    );
  });
}
