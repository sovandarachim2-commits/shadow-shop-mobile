import 'dart:async';

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
import 'package:shadow_shop_mobile/features/customer/products/product_detail_screen.dart';
import 'package:shadow_shop_mobile/features/customer/rewards/lucky_box/lucky_box_page.dart';

class _FilterOption<T> {
  const _FilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => StoreScreenState();
}

class StoreScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  late Future<List<Product>> _products;
  late Future<List<Map<String, dynamic>>> _sets;
  late Future<List<Map<String, dynamic>>> _categories;
  late Future<List<Map<String, dynamic>>> _brands;
  late Future<Map<String, dynamic>> _homeFeed;
  late Future<Map<String, dynamic>> _siteSettings;
  int _tab = 0;
  int? _categoryId;
  int? _brandId;
  String _ordering = '-created_at';
  int _bannerIndex = 0;

  void setTab(int tab) => setState(() => _tab = tab);

  @override
  void initState() {
    super.initState();
    _products = _loadProducts();
    _sets = _loadSets();
    _categories = context.read<ShopState>().service.categories();
    _brands = context.read<ShopState>().service.brands();
    _homeFeed = context.read<ShopState>().service.homeFeed();
    _siteSettings = context.read<ShopState>().service.siteSettings();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() =>
      context.read<ShopState>().service.products(
            search: _search.text,
            categoryId: _categoryId,
            brandId: _brandId,
            limit: 1000,
            ordering: _ordering,
          );

  Future<List<Map<String, dynamic>>> _loadSets() {
    if (_categoryId != null || _brandId != null) {
      return Future.value(const []);
    }
    return context.read<ShopState>().service.productSets(
          search: _search.text,
          limit: 1000,
          ordering: _ordering == 'retail_price'
              ? 'price'
              : _ordering == '-retail_price'
                  ? '-price'
                  : _ordering == '-rating'
                      ? '-created_at'
                      : _ordering,
        );
  }

  void _reloadCatalog() {
    _products = _loadProducts();
    _sets = _loadSets();
  }

  void _searchProducts(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _tab = 1;
      _reloadCatalog();
    });
  }

  void _onSearchChanged(String value) {
    if (_tab != 1) setState(() => _tab = 1);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _searchProducts(value);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: _tab <= 1
              ? _searchField()
              : _tab == 3
                  ? const Text('Cart')
                  : _brandTitle(),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WishlistView()),
              ),
              style: IconButton.styleFrom(foregroundColor: brandColor),
              icon: const Icon(Icons.favorite_border_rounded),
              tooltip: 'Wishlist',
            ),
            IconButton(
              onPressed: () => setState(() => _tab = 5),
              tooltip: 'Account',
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ],
        ),
        body: switch (_tab) {
          1 => _catalog(),
          2 => const RewardsView(),
          3 => const CartView(),
          4 => const OrdersView(),
          5 => const ProfileView(),
          _ => _homeFeedView(),
        },
        bottomNavigationBar: _bottomNavigation(),
      );

  Widget _searchField() => RawAutocomplete<Product>(
        key: const ValueKey('store-search'),
        textEditingController: _search,
        focusNode: _searchFocus,
        displayStringForOption: (product) => product.name,
        optionsBuilder: (value) async {
          final query = value.text.trim();
          if (query.isEmpty) return const Iterable<Product>.empty();
          try {
            return await context.read<ShopState>().service.products(
                  search: query,
                  limit: 8,
                );
          } catch (_) {
            return const Iterable<Product>.empty();
          }
        },
        onSelected: (product) {
          _searchFocus.unfocus();
          _searchProducts(product.name);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                onSubmitted();
                _searchProducts(value);
              },
              decoration: InputDecoration(
                hintText: 'Search products',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: brandColor),
                ),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final products = options.toList();
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              color: Colors.white,
              shadowColor: const Color(0x33101828),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 320,
                  maxWidth: MediaQuery.sizeOf(context).width - 32,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFFF2E8ED),
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      onTap: () => onSelected(product),
                      leading: _searchSuggestionImage(product),
                      title: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

  Widget _searchSuggestionImage(Product product) {
    final imageUrl = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: imageUrl == null
            ? const ColoredBox(
                color: Color(0xFFFFFBFD),
                child: Icon(Icons.spa_outlined, color: brandColor, size: 20),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFFFFBFD),
                  child: Icon(Icons.image_not_supported_outlined, size: 18),
                ),
              ),
      ),
    );
  }

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
              _navItem(3, 'Cart', Icons.shopping_bag_outlined,
                  Icons.shopping_bag_rounded),
              _navItem(4, 'My Orders', Icons.inventory_2_outlined,
                  Icons.inventory_2_rounded),
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
                    _categoryId = int.tryParse('${category['id']}');
                    _reloadCatalog();
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
      {required IconData icon, Color accent = brandColor}) {
    final cardWidth =
        (MediaQuery.sizeOf(context).width * .43).clamp(164.0, 230.0).toDouble();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeading(title, icon: icon, color: accent),
      SizedBox(
        height: cardWidth * 1.48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: cardWidth,
            child: ProductCard(product: products[index]),
          ),
        ),
      ),
    ]);
  }

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
        onRefresh: () async {
          setState(_reloadCatalog);
          await Future.wait([_products, _sets]);
        },
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
                final products = snapshot.data ?? [];
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sets,
                  builder: (context, setSnapshot) {
                    if (setSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        products.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (setSnapshot.hasError && products.isEmpty) {
                      return SliverFillRemaining(
                        child: _errorState(setSnapshot.error),
                      );
                    }
                    final sets = setSnapshot.data ?? [];
                    if (products.isEmpty && sets.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('No products found')),
                      );
                    }
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
                              Text('${products.length + sets.length} items',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                      if (sets.isNotEmpty || products.isNotEmpty)
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
                            itemCount: sets.length + products.length,
                            itemBuilder: (context, index) {
                              if (index < sets.length) {
                                final item = sets[index];
                                return ProductCard(
                                  product: Product.fromSetJson(item),
                                  setItems: Product.setItemsFrom(item),
                                );
                              }
                              return ProductCard(
                                product: products[index - sets.length],
                              );
                            },
                          ),
                        ),
                    ]);
                  },
                );
              },
            ),
          ],
        ),
      );

  Widget _productSetCard(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id']}') ?? 0;
    final price = double.tryParse('${item['display_price']}') ?? 0;
    final setItems = item['items'] is List ? item['items'] as List : const [];
    final brands = setItems
        .whereType<Map>()
        .map((setItem) => '${setItem['brand_name'] ?? ''}'.trim())
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .join(', ');
    final product = Product(
      id: id,
      productSetId: id,
      isProductSet: true,
      name: '${item['name'] ?? 'Product set'}',
      description: '${item['description'] ?? ''}',
      imageUrl: item['image_url']?.toString(),
      price: price,
      oldPrice: double.tryParse('${item['old_price']}'),
      stock: int.tryParse('${item['current_stock']}') ?? 0,
      available: item['is_available_for_sale'] != false,
      availabilityStatus: (item['availability_status'] ?? 'auto').toString(),
      isFlashSale: item['is_flash_sale_active'] == true,
      flashSaleMaxOrderQty: int.tryParse('${item['flash_sale_max_order_qty']}'),
    );

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x0F101828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF2E8ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFFFBFD),
              padding: const EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: product.imageUrl == null
                    ? const Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: brandColor,
                      )
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: brandColor,
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brands.isEmpty ? 'Product set' : brands,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: brandColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: product.canAddMore(0)
                          ? () {
                              context.read<ShopState>().add(product);
                              showStoreMessage(
                                context,
                                'Added to cart',
                                icon: Icons.check_circle_rounded,
                              );
                            }
                          : null,
                      tooltip: 'Add product set to cart',
                      color: brandColor,
                      disabledColor: const Color(0xFFD0D5DD),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shop products',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _categories,
            builder: (context, categorySnapshot) =>
                FutureBuilder<List<Map<String, dynamic>>>(
              future: _brands,
              builder: (context, brandSnapshot) {
                final categories = categorySnapshot.data ?? const [];
                final brands = brandSnapshot.data ?? const [];
                return Row(
                  children: [
                    Expanded(
                      child: _filterDropdown<int?>(
                        value: _categoryId,
                        hint: 'All Categories',
                        items: [
                          const _FilterOption<int?>(
                            value: null,
                            label: 'All Categories',
                          ),
                          ...categories.map(
                            (category) => _FilterOption<int?>(
                              value: int.tryParse('${category['id']}'),
                              label: '${category['name'] ?? ''}',
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _categoryId = value;
                          _reloadCatalog();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _filterDropdown<int?>(
                        value: _brandId,
                        hint: 'All Brands',
                        items: [
                          const _FilterOption<int?>(
                            value: null,
                            label: 'All Brands',
                          ),
                          ...brands.map(
                            (brand) => _FilterOption<int?>(
                              value: int.tryParse('${brand['id']}'),
                              label: '${brand['name'] ?? ''}',
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _brandId = value;
                          _reloadCatalog();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _filterDropdown<String>(
                        value: _ordering,
                        hint: 'Newest',
                        items: const [
                          _FilterOption(value: '-created_at', label: 'Newest'),
                          _FilterOption(
                              value: 'retail_price',
                              label: 'Price: low to high'),
                          _FilterOption(
                              value: '-retail_price',
                              label: 'Price: high to low'),
                          _FilterOption(value: '-rating', label: 'Best rated'),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _ordering = value;
                            _reloadCatalog();
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  Widget _filterDropdown<T>({
    required T value,
    required String hint,
    required List<_FilterOption<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final selectedLabel = items
        .where((item) => item.value == value)
        .map((item) => item.label)
        .firstOrNull;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .65,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item.value == value;
                        return ListTile(
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? brandColor
                                  : const Color(0xFF344054),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: brandColor)
                              : null,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            onChanged(item.value);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7EC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedLabel ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

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
                  () => _products = _loadProducts(),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
