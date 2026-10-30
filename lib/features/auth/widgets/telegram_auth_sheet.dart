import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> showTelegramAuthSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => const TelegramAuthSheet(),
  );
}

class TelegramAuthSheet extends StatefulWidget {
  const TelegramAuthSheet({super.key});

  @override
  State<TelegramAuthSheet> createState() => _TelegramAuthSheetState();
}

class _TelegramAuthSheetState extends State<TelegramAuthSheet> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handlingAuth = false;
  String _botUsername = 'invoicesheets_bot';

  @override
  void initState() {
    super.initState();
    // Initialize controller synchronously so build() never throws LateInitializationError
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'TelegramAuthChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _processAuthPayloadString(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null) _checkInterceptUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkInterceptUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Initial load with default bot
    _controller.loadHtmlString(_generateHtml(_botUsername), baseUrl: 'https://oauth.telegram.org');

    // Async update if bot username is configured differently on server
    _fetchBotConfig();
  }

  Future<void> _fetchBotConfig() async {
    try {
      final state = context.read<ShopState>();
      final configRes = await state.service.api.dio.get('auth/telegram/config/');
      final data = configRes.data;
      if (data is Map && data['bot_username'] != null) {
        final serverBot = data['bot_username'].toString();
        if (serverBot.isNotEmpty && serverBot != _botUsername && mounted) {
          _botUsername = serverBot;
          _controller.loadHtmlString(_generateHtml(_botUsername), baseUrl: 'https://oauth.telegram.org');
        }
      }
    } catch (_) {}
  }

  String _generateHtml(String botUsername) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 32px 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #FFFFFF;
      color: #1E293B;
      min-height: 260px;
    }
    .header {
      font-size: 16px;
      font-weight: 700;
      color: #0F172A;
      margin-bottom: 6px;
      text-align: center;
    }
    .sub {
      font-size: 13px;
      color: #64748B;
      margin-bottom: 24px;
      text-align: center;
    }
    .widget-box {
      min-height: 48px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .footer {
      margin-top: 24px;
      font-size: 11px;
      color: #94A3B8;
      text-align: center;
      line-height: 1.4;
      max-width: 260px;
    }
  </style>
</head>
<body>
  <div class="header">Log in with Telegram</div>
  <div class="sub">Tap the button below to authorize with @$botUsername</div>
  <div class="widget-box">
    <script async src="https://telegram.org/js/telegram-widget.js?22"
            data-telegram-login="$botUsername"
            data-size="large"
            data-radius="14"
            data-onauth="onTelegramAuth(user)"
            data-request-access="write"></script>
  </div>
  <div class="footer">
    A confirmation message will appear in Telegram. Confirm to sign in automatically.
  </div>
  <script type="text/javascript">
    function onTelegramAuth(user) {
      if (window.TelegramAuthChannel) {
        window.TelegramAuthChannel.postMessage(JSON.stringify(user));
      }
    }
  </script>
</body>
</html>
''';
  }

  bool _checkInterceptUrl(String rawUrl) {
    if (_handlingAuth) return true;
    try {
      final uri = Uri.parse(rawUrl);
      Map<String, dynamic>? payload;

      // Case 1: Telegram OAuth hash containing tgAuthResult
      if (uri.hasFragment) {
        final frag = uri.fragment;
        final fragParams = Uri.splitQueryString(frag);
        if (fragParams.containsKey('tgAuthResult')) {
          final b64 = fragParams['tgAuthResult']!.replaceAll('-', '+').replaceAll('_', '/');
          final decoded = utf8.decode(base64.decode(base64.normalize(b64)));
          final obj = json.decode(decoded);
          if (obj is Map<String, dynamic>) payload = obj;
        } else if (fragParams.containsKey('id_token')) {
          payload = {'id_token': fragParams['id_token']};
        } else if (fragParams.containsKey('hash') && fragParams.containsKey('id')) {
          payload = Map<String, dynamic>.from(fragParams);
        }
      }

      // Case 2: Query params
      if (payload == null && uri.hasQuery) {
        if (uri.queryParameters.containsKey('tgAuthResult')) {
          final b64 = uri.queryParameters['tgAuthResult']!.replaceAll('-', '+').replaceAll('_', '/');
          final decoded = utf8.decode(base64.decode(base64.normalize(b64)));
          final obj = json.decode(decoded);
          if (obj is Map<String, dynamic>) payload = obj;
        } else if (uri.queryParameters.containsKey('id_token')) {
          payload = {'id_token': uri.queryParameters['id_token']};
        } else if (uri.queryParameters.containsKey('hash') && uri.queryParameters.containsKey('id')) {
          payload = Map<String, dynamic>.from(uri.queryParameters);
        }
      }

      if (payload != null) {
        _submitAuthPayload(payload);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _processAuthPayloadString(String jsonString) {
    if (_handlingAuth) return;
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        _submitAuthPayload(decoded);
      }
    } catch (_) {}
  }

  Future<void> _submitAuthPayload(Map<String, dynamic> payload) async {
    if (_handlingAuth) return;
    setState(() => _handlingAuth = true);

    try {
      final state = context.read<ShopState>();
      final success = await state.loginWithTelegram(payload);

      if (!mounted) return;
      if (success) {
        // Pop Telegram bottom sheet
        Navigator.of(context).pop();
        // Also pop the parent auth modal sheet if open
        Navigator.of(context, rootNavigator: true).maybePop(true);

        showStoreMessage(
          context,
          'Welcome, ${state.user?['first_name'] ?? state.user?['username'] ?? 'Customer'}!',
          icon: Icons.check_circle_rounded,
        );
      } else {
        setState(() => _handlingAuth = false);
        showStoreMessage(
          context,
          state.error ?? 'Telegram sign-in failed. Please try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _handlingAuth = false);
      showStoreMessage(
        context,
        friendlyError(e),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/telegram.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF229ED9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Telegram Sign In',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading || _handlingAuth)
                  Container(
                    color: Colors.white.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _handlingAuth ? 'Signing you in...' : 'Connecting to Telegram...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
