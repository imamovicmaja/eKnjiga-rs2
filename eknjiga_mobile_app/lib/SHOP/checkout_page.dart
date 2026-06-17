import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/confirm_dialog.dart';
import '../models/cart_item.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../widgets/book_image.dart';
import '../HOME/cart.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? items;
  final Book? book;
  final bool? isPdfPurchase;

  const CheckoutPage.fromCart({super.key, required List<CartItem> items})
    : items = items,
      book = null,
      isPdfPurchase = null;

  const CheckoutPage.fromBook({
    super.key,
    required Book book,
    required bool isPdfPurchase,
  }) : items = null,
       book = book,
       isPdfPurchase = isPdfPurchase;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const Color topColor = Color(0xFFD4D8F6);
  static const Color midColor = Color(0xFF8D9EDB);
  static const Color bottomColor = Color(0xFFB59C4A);

  bool busy = false;
  late List<_CheckoutItem> _items;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  static const String _pendingPaypalOrderIdKey = 'pending_paypal_order_id';

  String? _pendingPaypalOrderId;
  List<_CheckoutItem> _pendingItemsSnapshot = [];
  bool _handlingPayPalDeepLink = false;

  @override
  void initState() {
    super.initState();

    final List<CartItem> sourceItems =
        widget.items ??
        [
          CartItem(
            bookId: widget.book!.id,
            name: widget.book!.name,
            authors: widget.book!.authors,
            coverImage: widget.book!.coverImage,
            price: widget.book!.price,
            isPdfPurchase: widget.isPdfPurchase ?? false,
            quantity: 1,
          ),
        ];

    final List<_CheckoutItem> temp = [];

    for (final item in sourceItems) {
      final existingIndex = temp.indexWhere(
        (e) =>
            e.item.bookId == item.bookId &&
            e.item.isPdfPurchase == item.isPdfPurchase,
      );

      if (existingIndex >= 0) {
        temp[existingIndex].qty += item.quantity;
      } else {
        temp.add(_CheckoutItem(item: item, qty: item.quantity));
      }
    }

    _items = temp;

    _initializePayPalDeepLinks();
  }

  Future<void> _initializePayPalDeepLinks() async {
    _linkSub = _appLinks.uriLinkStream.listen(
      _handlePayPalDeepLink,
      onError: (_) {},
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handlePayPalDeepLink(initialUri);
      }
    } catch (_) {}
  }

  Future<void> _savePendingPaypalOrder(String paypalOrderId) async {
    _pendingPaypalOrderId = paypalOrderId;

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_pendingPaypalOrderIdKey, paypalOrderId);
  }

  Future<String?> _loadPendingPaypalOrderId() async {
    if (_pendingPaypalOrderId != null) {
      return _pendingPaypalOrderId;
    }

    final sp = await SharedPreferences.getInstance();
    _pendingPaypalOrderId = sp.getString(_pendingPaypalOrderIdKey);
    return _pendingPaypalOrderId;
  }

  Future<void> _clearPendingPaypalState() async {
    _pendingPaypalOrderId = null;
    _pendingItemsSnapshot = [];

    final sp = await SharedPreferences.getInstance();
    await sp.remove(_pendingPaypalOrderIdKey);
  }

  Future<void> _handlePayPalDeepLink(Uri uri) async {
    final url = uri.toString();

    final isReturn = url.startsWith(ApiService.paypalReturnUrlPrefix);
    final isCancel = url.startsWith(ApiService.paypalCancelUrlPrefix);

    if (!isReturn && !isCancel) return;
    if (_handlingPayPalDeepLink) return;

    final pendingPaypalOrderId = await _loadPendingPaypalOrderId();
    if (pendingPaypalOrderId == null || pendingPaypalOrderId.isEmpty) return;

    _handlingPayPalDeepLink = true;

    if (mounted) {
      setState(() => busy = true);
    }

    if (isCancel) {
      await _clearPendingPaypalState();
      _handlingPayPalDeepLink = false;

      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plaćanje je otkazano.')));
      return;
    }

    try {
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) {
        throw Exception('PayPal token nije pronađen.');
      }

      await ApiService.paypalCaptureOrder(token);

      if (widget.items != null) {
        for (final checkoutItem in _pendingItemsSnapshot) {
          Cart.I.remove(checkoutItem.item);
        }
      }

      await _clearPendingPaypalState();
      _handlingPayPalDeepLink = false;

      if (!mounted) return;
      setState(() => busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plaćanje uspješno završeno!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      await _clearPendingPaypalState();
      _handlingPayPalDeepLink = false;

      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PayPal greška: $e')));
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  double get total =>
      _items.fold(0, (sum, item) => sum + item.item.price * item.qty);

  bool get hasPdf => _items.any((i) => i.item.isPdfPurchase);

  String _price(double value) => '${value.toStringAsFixed(2)} KM';

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}.';
  }

  Future<void> _confirmCashOnDelivery() async {
    if (hasPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF knjige se mogu platiti samo online.'),
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Korpa je prazna.')));
      return;
    }

    setState(() => busy = true);

    try {
      await ApiService.createOrder(
        type: 0,
        orderItems:
            _items
                .map(
                  (i) => {
                    "bookId": i.item.bookId,
                    "quantity": i.qty,
                    "isPdfPurchase": i.item.isPdfPurchase,
                  },
                )
                .toList(),
      );

      if (widget.items != null) {
        for (final checkoutItem in _items) {
          Cart.I.remove(checkoutItem.item);
        }
      }

      if (!mounted) return;
      setState(() => busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Narudžba uspješno evidentirana!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }

  Future<void> _confirmOnlinePayment() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Korpa je prazna.')));
      return;
    }

    setState(() => busy = true);

    try {
      final orderId = await ApiService.createOrder(
        type: 0,
        orderItems:
            _items
                .map(
                  (i) => {
                    "bookId": i.item.bookId,
                    "quantity": i.qty,
                    "isPdfPurchase": i.item.isPdfPurchase,
                  },
                )
                .toList(),
      );

      final paypal = await ApiService.paypalCreateOrder(
        orderId: orderId,
        amount: total,
        currency: 'EUR',
      );

      _pendingItemsSnapshot =
          _items.map((x) => _CheckoutItem(item: x.item, qty: x.qty)).toList();
      await _savePendingPaypalOrder(paypal.id);

      await launchUrl(
        Uri.parse(paypal.approveLink),
        customTabsOptions: const CustomTabsOptions(
          shareState: CustomTabsShareState.off,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      await _clearPendingPaypalState();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiry = DateTime.now().add(const Duration(days: 7));
    final address =
        _items.isNotEmpty
            ? _items.first.item.pickupAddress
            : 'Poslovnica eKnjiga, Zmaja od Bosne 12, Sarajevo';

    return Scaffold(
      backgroundColor: topColor,
      appBar: AppBar(
        backgroundColor: topColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Potvrda kupovine',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [topColor, midColor, bottomColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Expanded(
                  child:
                      _items.isEmpty
                          ? const Center(
                            child: Text(
                              'Korpa je prazna.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          )
                          : ListView(
                            children:
                                _items
                                    .map((e) => _checkoutItemCard(e))
                                    .toList(),
                          ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ukupna cijena: ${_price(total)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!hasPdf) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rok za plaćanje / preuzimanje: ${_formatDate(expiry)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Adresa poslovnice: $address',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        busy
                            ? null
                            : () async {
                              final confirmed = await showAppConfirmDialog(
                                context: context,
                                title: 'Potvrda plaćanja',
                                message:
                                    'Da li želite nastaviti na online plaćanje putem PayPal-a?',
                                confirmText: 'Nastavi',
                              );

                              if (!confirmed) return;

                              await _confirmOnlinePayment();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96A6DA),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child:
                        busy
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'PLATI ONLINE',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                  ),
                ),
                if (!hasPdf) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          busy
                              ? null
                              : () async {
                                final confirmed = await showAppConfirmDialog(
                                  context: context,
                                  title: 'Potvrda narudžbe',
                                  message:
                                      'Da li ste sigurni da želite poslati ovu narudžbu?',
                                  confirmText: 'Pošalji',
                                );

                                if (!confirmed) return;

                                await _confirmCashOnDelivery();
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.96),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'PLAĆANJE POUZEĆEM',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutItemCard(_CheckoutItem entry) {
    final ci = entry.item;
    final imageUrl = ApiService.getImageUrl(ci.coverImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (ci.coverImage != null && ci.coverImage!.isNotEmpty)
              ? BookImage(
                url: imageUrl,
                width: 74,
                height: 102,
                borderRadius: 12,
              )
              : Container(
                width: 74,
                height: 102,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.book),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ci.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ci.authors.join(', '),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  ci.isPdfPurchase ? 'PDF' : 'Hard copy',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Količina: ${entry.qty}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  _price(ci.price * entry.qty),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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

class _CheckoutItem {
  final CartItem item;
  int qty;

  _CheckoutItem({required this.item, required this.qty});
}
