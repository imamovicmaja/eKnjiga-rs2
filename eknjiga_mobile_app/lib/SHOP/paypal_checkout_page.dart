import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_service.dart';

class PaypalCheckoutPage extends StatefulWidget {
  final String approveUrl;
  final String paypalOrderId;

  /// URL-ovi koje si postavio u backend config:
  /// PayPal:ReturnUrl  -> npr. https://example.com/api/paypal/return
  /// PayPal:CancelUrl  -> npr. https://example.com/api/paypal/cancel
  ///
  /// Mi ćemo u WebView pratiti kad user dođe na return/cancel.
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _busy = true),
          onPageFinished: (_) => setState(() => _busy = false),
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            if (_handled) {
              return NavigationDecision.prevent;
            }

            if (url.startsWith('eknjiga://paypal-cancel')) {
              _handled = true;
              if (mounted) Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }

            if (url.startsWith('eknjiga://paypal-return')) {
              _handled = true;

              try {
                final uri = Uri.parse(url);
                final tokenFromUrl = uri.queryParameters['token'];

                if (tokenFromUrl == null || tokenFromUrl.isEmpty) {
                  throw Exception('PayPal token nije pronađen u return URL-u.');
                }

                await ApiService.paypalCaptureOrder(tokenFromUrl);

                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PayPal capture greška: $e')),
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
