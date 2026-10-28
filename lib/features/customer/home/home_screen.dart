import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/models/product.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:shadow_shop_mobile/features/customer/products/widgets/product_card.dart';
import 'package:shadow_shop_mobile/features/customer/cart/cart_screen.dart';
import 'package:shadow_shop_mobile/features/customer/orders/orders_screen.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/rewards_screen.dart';
import 'package:shadow_shop_mobile/features/customer/wishlist/wishlist_screen.dart';
import 'package:shadow_shop_mobile/features/customer/profile/profile_screen.dart';
import 'package:shadow_shop_mobile/features/customer/products/product_sets/product_sets_page.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/lucky_box/lucky_box_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => StoreScreenState();
}

class StoreScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late Future<List<Product>> _products;
  late Future<List<Map<String, dynamic>>> _categories;
  late Future<Map<String, dynamic>> _homeFeed;
  late Future<Map<String, dynamic>> _siteSettings;
  int _tab = 0;
  String _category = 'All';
  int _bannerIndex = 0;

  void setTab(int tab) => setState(() => _tab = tab);

  @override
  void initState() {
    super.initState();
    _products = context.read<ShopState>().service.products();
    _categories = context.read<ShopState>().service.categories();
    _homeFeed = context.read<ShopState>().service.homeFeed();
    _siteSettings = context.read<ShopState>().service.siteSettings();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _searchProducts(String value) => setState(
        () => _products =
            context.read<ShopState>().service.products(search: value),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: _brandTitle(),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WishlistView()),
              ),
              style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE3ED),
                  foregroundColor: brandColor),
              icon: const Icon(Icons.favorite_border_rounded),
              tooltip: 'Wishlist',
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Cart')),
                  body: const CartView(),
                ),
              )),
              tooltip: 'Cart',
              icon: Badge(
                isLabelVisible: context.watch<ShopState>().itemCount > 0,
                label: Text('${context.watch<ShopState>().itemCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ],
        ),
        body: switch (_tab) {
          1 => _catalog(),
          2 => const RewardsView(),
          3 => const OrdersView(),
          4 => const ProfileView(),
          _ => _homeFeedView(),
        },
        bottomNavigationBar: _bottomNavigation(),
      );

  Widget _bottomNavigation() => SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFF2DDE8))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 18,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Row(children: [
              _navItem(0, 'Home', Icons.home_outlined, Icons.home_rounded),
              _navItem(1, 'Products', Icons.shopping_bag_outlined,
                  Icons.shopping_bag_rounded),
              const SizedBox(width: 62),
              _navItem(3, 'My Orders', Icons.inventory_2_outlined,
                  Icons.inventory_2_rounded),
              _navItem(4, 'Account', Icons.person_outline_rounded,
                  Icons.person_rounded),
            ]),
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  onTap: () => setState(() => _tab = 2),
                  borderRadius: BorderRadius.circular(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF24792), Color(0xFFD629D7)]),
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x30EC2F83),
                              blurRadius: 22,
                              spreadRadius: 3)
                        ],
                      ),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: Colors.white, size: 25),
                    ),
                    const SizedBox(height: 2),
                    Text('Rewards',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                _tab == 2 ? FontWeight.w800 : FontWeight.w600,
                            color: _tab == 2
                                ? brandColor
                                : const Color(0xFF667085))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _navItem(int index, String label, IconData icon, IconData activeIcon) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 5),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Icon(selected ? activeIcon : icon,
                size: 23,
                color: selected ? brandColor : const Color(0xFF667085)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? brandColor : const Color(0xFF667085))),
            const SizedBox(height: 3),
            AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                    color: selected ? brandColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(4))),
          ]),
        ),
      ),
    );
  }

  Widget _brandTitle() => FutureBuilder<Map<String, dynamic>>(
        future: _siteSettings,
        builder: (context, snapshot) {
          final data = snapshot.data ?? const <String, dynamic>{};
          final name = '${data['store_name'] ?? 'Shadow Shop'}';
          final logo = data['logo_url']?.toString();
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC2F83), Color(0xFFD629D7)],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(color: Color(0x22EC2F83), blurRadius: 10)
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: logo == null || logo.isEmpty
                  ? const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 20)
                  : Image.network(logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.shopping_bag_rounded,
                          color: Colors.white,
                          size: 20)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ]);
        },
      );

  Widget _homeFeedView() => FutureBuilder<Map<String, dynamic>>(
        future: _homeFeed,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error);
          }
          final feed = snapshot.data ?? const <String, dynamic>{};
          final categories = (feed['categories'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .where((row) => row['parent'] == null)
              .take(10)
              .toList();
          final banners = (feed['banners'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final bestSellers = _feedProducts(feed['best_sellers']);
          final flashSale = _feedProducts(feed['flash_sale']);
          final newArrivals = _feedProducts(feed['new_arrivals']);
          final brands = (feed['brands'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          return RefreshIndicator(
            color: brandColor,
            onRefresh: () async {
              setState(() =>
                  _homeFeed = context.read<ShopState>().service.homeFeed());
              await _homeFeed;
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (categories.isNotEmpty) _categorySection(categories),
                if (banners.isNotEmpty) _bannerSection(banners),
                _specialLinks(),
                if (flashSale.isNotEmpty)
                  _productSection('Flash Sale', flashSale,
                      icon: Icons.bolt_rounded,
                      accent: const Color(0xFFF04472)),
                if (bestSellers.isNotEmpty)
                  _productSection('Best Sellers', bestSellers,
                      icon: Icons.local_fire_department_outlined),
                if (brands.isNotEmpty) _brandSection(brands),
                if (newArrivals.isNotEmpty)
                  _productSection('New Arrivals', newArrivals,
                      icon: Icons.fiber_new_rounded),
                if (categories.isEmpty &&
                    banners.isEmpty &&
                    bestSellers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Text('Welcome to Shadow Shop',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      FilledButton(
                          onPressed: () => setState(() => _tab = 1),
                          child: const Text('Browse products')),
                    ]),
                  ),
              ],
            ),
          );
        },
      );

  List<Product> _feedProducts(dynamic raw) => (raw as List? ?? const [])
      .whereType<Map>()
      .map((row) => Product.fromJson(Map<String, dynamic>.from(row)))
      .toList();

  Widget _sectionHeading(String title,
          {required IconData icon, Color color = brandColor}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900))),
          TextButton(
              onPressed: () => setState(() => _tab = 1),
              style: TextButton.styleFrom(foregroundColor: brandColor),
              child: const Text('View all')),
        ]),
      );

  Widget _categorySection(List<Map<String, dynamic>> categories) => Container(
        color: Colors.white,
        child: Column(children: [
          _sectionHeading('Categories', icon: Icons.shopping_bag_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisExtent: 88,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 6),
              itemBuilder: (context, index) {
                final category = categories[index];
                final image = category['image_url']?.toString();
                return InkWell(
                  onTap: () => setState(() {
                    _category = '${category['name'] ?? 'All'}';
                    _tab = 1;
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFEAECEF)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: image == null || image.isEmpty
                          ? const Icon(Icons.spa_outlined,
                              color: Color(0xFF475569), size: 23)
                          : Image.network(image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.spa_outlined,
                                  color: Color(0xFF475569))),
                    ),
                    const SizedBox(height: 6),
                    Text('${category['name'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF344054))),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ]),
      );

  Widget _bannerSection(List<Map<String, dynamic>> banners) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Promotions', icon: Icons.card_giftcard_outlined),
          SizedBox(
            height: 174,
            child: PageView.builder(
              itemCount: banners.length,
              onPageChanged: (index) => setState(() => _bannerIndex = index),
              itemBuilder: (context, index) {
                final banner = banners[index];
                final image = banner['image_url']?.toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: InkWell(
                    onTap: () => setState(() => _tab = 1),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(22),
                        image: image == null || image.isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(image), fit: BoxFit.cover),
                      ),
                      child: Stack(children: [
                        if (image != null && image.isNotEmpty)
                          Positioned.fill(
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xAA1F1235),
                                            Color(0x001F1235)
                                          ])))),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if ('${banner['discount_text'] ?? ''}'
                                    .isNotEmpty)
                                  Text('${banner['discount_text']}',
                                      style: const TextStyle(
                                          color: Color(0xFFFFD5E8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                Text(
                                    '${banner['title'] ?? 'Shop the latest offers'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        height: 1.1,
                                        fontWeight: FontWeight.w900)),
                                if ('${banner['subtitle'] ?? ''}'.isNotEmpty)
                                  Text('${banner['subtitle']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(
                                    '${banner['button_text'] ?? 'Shop now'}  ›',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                              ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _bannerIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: i == _bannerIndex
                            ? brandColor
                            : const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(8)),
                  ),
              ]),
            ),
        ],
      );

  Widget _productSection(String title, List<Product> products,
          {required IconData icon, Color accent = brandColor}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeading(title, icon: icon, color: accent),
        SizedBox(
          height: 247,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
                width: 160, child: ProductCard(product: products[index])),
          ),
        ),
      ]);

  Widget _specialLinks() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
        child: Row(children: [
          Expanded(
            child: _specialLink(
              icon: Icons.inventory_2_outlined,
              title: 'Product sets',
              color: brandColor,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductSetsPage())),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _specialLink(
              icon: Icons.card_giftcard_outlined,
              title: 'Lucky Box',
              color: const Color(0xFF8738C7),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LuckyBoxPage())),
            ),
          ),
        ]),
      );

  Widget _specialLink({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
            ]),
          ),
        ),
      );

  Widget _brandSection(List<Map<String, dynamic>> brands) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Shop by brand', icon: Icons.auto_awesome_outlined),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final brand = brands[index];
                final logo = brand['logo_url']?.toString();
                return SizedBox(
                  width: 72,
                  child: Column(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: logo == null || logo.isEmpty
                          ? const Icon(Icons.spa_outlined, color: brandColor)
                          : ClipOval(
                              child: Image.network(logo,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.spa_outlined,
                                      color: brandColor))),
                    ),
                    const SizedBox(height: 5),
                    Text('${brand['name'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10)),
                  ]),
                );
              },
            ),
          ),
        ],
      );

  Widget _catalog() => RefreshIndicator(
        onRefresh: () async => setState(
          () => _products = context.read<ShopState>().service.products(
                search: _search.text,
              ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _homeHeader()),
            FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                if (snapshot.hasError)
                  return SliverFillRemaining(
                      child: _errorState(snapshot.error));
                final products = (snapshot.data ?? [])
                    .where((product) =>
                        _category == 'All' || product.categoryName == _category)
                    .toList();
                if (products.isEmpty)
                  return const SliverFillRemaining(
                    child: Center(child: Text('No products found')),
                  );
                return SliverMainAxisGroup(slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _search.text.isEmpty
                                  ? 'Shop all'
                                  : 'Search results',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text('${products.length} items',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .66,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: products[index]),
                    ),
                  ),
                ]);
              },
            ),
          ],
        ),
      );

  Widget _homeHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shop products',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _searchProducts,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                  onPressed: () => _searchProducts(_search.text),
                  icon: const Icon(Icons.arrow_forward_rounded)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _categories,
              builder: (context, snapshot) {
                final names = [
                  'All',
                  ...?snapshot.data
                      ?.where((item) => item['is_active'] != false)
                      .map((item) => (item['name'] ?? '').toString())
                ];
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: names.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(names[index]),
                    selected: _category == names[index],
                    selectedColor: const Color(0xFFFCE7F3),
                    labelStyle: TextStyle(
                        color: _category == names[index]
                            ? brandColor
                            : const Color(0xFF475467),
                        fontWeight: FontWeight.w700),
                    onSelected: (_) => setState(() => _category = names[index]),
                  ),
                );
              },
            ),
          ),
        ]),
      );

  Widget _errorState(Object? error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Could not load the store',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(friendlyError(error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(
                  () => _products = context.read<ShopState>().service.products(
                        search: _search.text,
                      ),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
