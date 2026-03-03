import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_service.dart';

class PaypalCheckoutPage extends StatefulWidget {
  final String approveUrl;
  final String paypalOrderId;

  /// Mora se poklapati sa backend configom:
  /// ReturnUrl:  eknjiga://paypal-return
  /// CancelUrl:  eknjiga://paypal-cancel
  final String returnUrlPrefix;
  final String cancelUrlPrefix;

  const PaypalCheckoutPage({
    super.key,
    required this.approveUrl,
    required this.paypalOrderId,
    required this.returnUrlPrefix,
    required this.cancelUrlPrefix,
  });

  @override
  State<PaypalCheckoutPage> createState() => _PaypalCheckoutPageState();
}

class _PaypalCheckoutPageState extends State<PaypalCheckoutPage> {
  late final WebViewController _controller;

  bool _busy = true;
  bool _handled = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _busy = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _busy = false);
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

debugPrint('PayPal NAV: $url');

if (_handled) return NavigationDecision.prevent;

final isHttp = url.startsWith('http://') || url.startsWith('https://');
final isReturn = url.startsWith(widget.returnUrlPrefix);
final isCancel = url.startsWith(widget.cancelUrlPrefix);

// ✅ dozvoli webview “internal” URL-ove koje PayPal koristi
final isInternalOk =
    url == 'about:blank' ||
    url.startsWith('about:blank') ||
    url.startsWith('data:') ||
    url.startsWith('blob:');

// ⛔ samo blokiraj ono što je baš external/intent
final isBlockedScheme =
    url.startsWith('intent://') ||
    url.startsWith('market://') ||
    url.startsWith('paypal://') ||
    url.startsWith('tel:') ||
    url.startsWith('mailto:');

if (isBlockedScheme) {
  return NavigationDecision.prevent;
}

// Ako nije http/https niti internal niti return/cancel -> blokiraj
if (!isHttp && !isInternalOk && !isReturn && !isCancel) {
  return NavigationDecision.prevent;
}

if (isCancel) {
  _handled = true;
  if (mounted) Navigator.pop(context, false);
  return NavigationDecision.prevent;
}

if (isReturn) {
  _handled = true;
  try {
    final uri = Uri.parse(url);
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      throw Exception('PayPal token nije pronađen.');
    }

    await ApiService.paypalCaptureOrder(token);

    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PayPal greška: $e')),
      );
      Navigator.pop(context, false);
    }
  }
  return NavigationDecision.prevent;
}

return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approveUrl));
  }

  @override
  void dispose() {
    // dodatna sigurnost – prekida WebView lifecycle
    _handled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal plaćanje'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
