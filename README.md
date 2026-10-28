# Shadow Shop Mobile

Flutter customer app for the existing Shadow Shop Django API. This folder is separate from the React website and does not contain a second backend.

## Source structure

Keep each layer in its own folder as the app grows:

```text
lib/
  main.dart
  app/                              App startup and session gate
  config/                           API and environment configuration
  theme/                            Shared colors and UI helpers
  models/                           Product and cart data models
  services/                         Django API client and endpoint methods
  state/                            Shared customer session and cart state
  features/
    auth/
      login_screen.dart
      register_screen.dart
    customer/
      home/home_screen.dart
      products/
        product_list_screen.dart
        product_detail_screen.dart
        widgets/product_card.dart
        product_sets/product_sets_page.dart
      cart/cart_screen.dart
      cart/checkout_screen.dart
      orders/orders_screen.dart
      orders/order_detail_screen.dart
      wishlist/wishlist_screen.dart
      rewards/rewards_screen.dart
      rewards/earn_points/earn_points_page.dart
      rewards/points_history/points_history_page.dart
      rewards/referral/referral_page.dart
      rewards/coupons/coupons_page.dart
      rewards/lucky_box/lucky_box_page.dart
      profile/profile_screen.dart
```

Each screen lives with its feature. Keep reusable API calls, models, and app-wide state in `services/`, `models/`, and `state/`; keep feature-specific widgets near the screen that uses them.

## Requirements

- Flutter stable SDK
- Android Studio with Android SDK (for Android builds)
- Existing Shadow Shop Django backend

Run `flutter doctor` and address Android toolchain issues. From this folder:

```powershell
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api
```

Use these API addresses for local development:

- Android emulator: `http://10.0.2.2:8001/api`
- iOS simulator: `http://127.0.0.1:8001/api`
- Physical phone: `http://YOUR_PC_LAN_IP:8001/api` (Django must listen on `0.0.0.0:8001`; allow the port through Windows Firewall)

The phone and development computer must be on the same network. For releases, provide the deployed HTTPS API URL. Do not ship a development URL.

## Included starter features

- Customer JWT login using the existing `/auth/login/` endpoint
- Customer registration and email code verification using existing auth endpoints
- Secure storage for access/refresh tokens
- Product catalog, search, category filters, availability, product details, and wishlist
- React-style storefront home feed with live categories, promotion banners, flash sales, best sellers, brands, and new arrivals
- Local cart with quantity controls and subtotal
- Delivery address entry, province delivery fee, and checkout via the existing order API
- Cash on Delivery, Bakong, ABA PayWay, ACLEDA, Wing, and Contact Sales payment choices
- Online payment status check against the backend; creating a QR/payment request does not mark an order paid
- My orders list and order detail/status history
- Customer profile edit, saved address creation, rewards balance/catalog, redemption, and daily check-in

The React app's exact payment settings and gateway behavior should be checked in the target environment. The Flutter app uses the backend checkout endpoint and displays a returned Bakong QR. ABA PayWay may still require a native/browser handoff matching the production gateway contract. Verify the full payment return flow in a supported test environment before release.

## API reference

The backend exposes schema/docs at `/api/schema/`, `/api/docs/`, and `/api/redoc/` when enabled. Current routes used by this starter:

- `POST /api/auth/login/`
- `POST /api/auth/refresh/`
- `GET /api/auth/me/`
- `GET /api/products/items/`
- `GET /api/products/home/`
- `GET /api/products/categories/`
- `GET /api/orders/list/?my_orders=1`
- `POST /api/orders/list/checkout/`
- `GET|POST|PATCH|DELETE /api/orders/cart/`
- `GET /api/orders/wishlist/`
- `GET|POST /api/orders/rewards/`
- `POST /api/orders/rewards/daily_checkin/`
- `POST /api/orders/rewards/exchange/`
- `GET|POST /api/auth/addresses/`

The development-only Android manifest allows HTTP for local API testing. Release builds should use an HTTPS API URL.

## Android build

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api
```

Configure a protected release signing key before distributing builds. iOS signing/builds require macOS and Xcode.
