import 'package:flutter/material.dart';
import './../HOME/home_page.dart';
import './../BOOKS/books_page.dart';
import './../MESSAGES/messages_page.dart';
import './../SETTINGS/settings_page.dart';
import '../HOME/cart.dart';
import '../HOME/reservation_cart.dart';
import '../services/api_service.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'checkout_page.dart';
import '../widgets/book_image.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _selectedIndex = 2;

  List<OrderResponse> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService.fetchOrders();
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmReservations() async {
    final reservationItems = ReservationCart.I.items;

    if (reservationItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemate knjiga u rezervacijama.')),
      );
      return;
    }

    try {
      await ApiService.createOrder(
        type: 1,
        totalPrice: ReservationCart.I.totalPrice,
        paymentStatus: 0,
        orderItems: reservationItems
            .map(
              (i) => {
                "bookId": i.bookId,
                "quantity": i.quantity,
                "unitPrice": i.price,
              },
            )
            .toList(),
      );

      ReservationCart.I.clear();
      await _loadOrders();

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je uspješno kreirana.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    }
  }

  Future<void> _cancelOrder(OrderResponse order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otkazivanje'),
        content: Text(
          order.type == 1
              ? 'Da li ste sigurni da želite otkazati ovu rezervaciju?'
              : 'Da li ste sigurni da želite otkazati ovu narudžbu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Da'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.cancelOrder(order.id);
      await _loadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            order.type == 1
                ? 'Rezervacija je otkazana.'
                : 'Narudžba je otkazana.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  String _price(double value) => '${value.toStringAsFixed(2)} KM';

  String _statusText(int s) {
    switch (s) {
      case 0:
        return "Poslano";
      case 1:
        return "U obradi";
      case 2:
        return "Završeno";
      case 3:
        return "Otkazano";
      default:
        return "Nepoznat status";
    }
  }

  String _paymentText(int s) {
    switch (s) {
      case 0:
        return "Nije plaćeno";
      case 1:
        return "Na čekanju";
      case 2:
        return "Plaćeno";
      case 3:
        return "Refundirano";
      case 4:
        return "Neuspjelo";
      default:
        return "Nepoznat status";
    }
  }

  bool _canCancel(OrderResponse order) {
    final isCompleted = order.orderStatus == 2;
    final isCancelled = order.orderStatus == 3;
    final isPaidOnline = order.paymentStatus == 2;

    return !isCompleted && !isCancelled && !isPaidOnline;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: Cart.I.notifier,
      builder: (context, cartItems, _) {
        return ValueListenableBuilder<List<CartItem>>(
          valueListenable: ReservationCart.I.notifier,
          builder: (context, reservationItems, __) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 212, 217, 246),
                elevation: 0,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'eKnjiga',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'For readers, by bookworms.',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadOrders,
                  ),
                ],
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 212, 217, 246),
                      Color.fromARGB(255, 141, 158, 219),
                      Color.fromARGB(255, 181, 156, 74),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Greška: $_error'))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                              children: [
                                sectionTitle('Moja korpa'),
                                if (cartItems.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Korpa je prazna'),
                                  )
                                else ...[
                                  ...cartItems.map((item) => _cartItemCard(item)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Ukupno:',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _price(Cart.I.totalPrice),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final changed = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CheckoutPage.fromCart(
                                                items: cartItems,
                                              ),
                                            ),
                                          );

                                          if (changed == true) {
                                            await _loadOrders();
                                            setState(() {});
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          Cart.I.hasPdf
                                              ? 'Završi kupovinu (online)'
                                              : 'Završi kupovinu',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                sectionTitle('Moje rezervacije'),
                                if (reservationItems.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('Nema knjiga u rezervacijama'),
                                  )
                                else ...[
                                  ...reservationItems
                                      .map((item) => _reservationItemCard(item)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Ukupno:',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _price(ReservationCart.I.totalPrice),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _confirmReservations,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child:
                                            const Text('Potvrdi rezervaciju'),
                                      ),
                                    ),
                                  ),
                                ],

                                sectionTitle('Moje narudžbe i rezervacije'),
                                const SizedBox(height: 12),
                                ..._orders.map(
                                  (order) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _orderItem(order),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.black,
                onTap: (index) {
                  if (index == _selectedIndex) return;

                  setState(() => _selectedIndex = index);

                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                      break;
                    case 1:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const BookPage()),
                      );
                      break;
                    case 2:
                      return;
                    case 3:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagesPage(),
                        ),
                      );
                      break;
                    case 4:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 32),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book, size: 32),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag, size: 32),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.comment, size: 32),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings, size: 32),
                    label: "",
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cartItemCard(CartItem item) {
    final imageUrl = ApiService.getImageUrl(item.coverImage);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageUrl.isNotEmpty
                  ? BookImage(
                      url: imageUrl,
                      width: 78,
                      height: 108,
                      borderRadius: 12,
                    )
                  : Container(
                      width: 78,
                      height: 108,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.book),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.authors.join(', '),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.isPdfPurchase ? 'PDF' : 'Hard copy',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    if (!item.isPdfPurchase) ...[
                      Text(
                        'Rok za plaćanje / preuzimanje:  ${_formatDate(item.createdAt.add(const Duration(days: 7)))}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adresa poslovnice: ${item.pickupAddress}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => Cart.I.remove(item)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!item.isPdfPurchase) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => Cart.I.decrease(item)),
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => Cart.I.increase(item)),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Količina: 1',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _price(item.price * item.quantity),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reservationItemCard(CartItem item) {
    final imageUrl = ApiService.getImageUrl(item.coverImage);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageUrl.isNotEmpty
                  ? BookImage(
                      url: imageUrl,
                      width: 78,
                      height: 108,
                      borderRadius: 12,
                    )
                  : Container(
                      width: 78,
                      height: 108,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.book),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.authors.join(', '),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Rezervacija',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    setState(() => ReservationCart.I.remove(item)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => ReservationCart.I.decrease(item)),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => ReservationCart.I.increase(item)),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _price(item.price * item.quantity),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderItem(OrderResponse order) {
    final typeText = order.type == 0 ? 'Kupovina' : 'Rezervacija';
    final d = order.orderDate.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(d.day)}.${two(d.month)}.${d.year}. ${two(d.hour)}:${two(d.minute)}';

    final totalStr = order.totalPrice.toStringAsFixed(2);

    final bookLines = order.orderItems
        .map(
          (oi) => '• ${oi.book?.name ?? "Nepoznata knjiga"} (x${oi.quantity})',
        )
        .join('\n');

    final canCancel = _canCancel(order);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  typeText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$totalStr KM",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Status: ${_statusText(order.orderStatus)}"),
            const SizedBox(height: 4),
            Text("Plaćanje: ${_paymentText(order.paymentStatus)}"),
            const SizedBox(height: 10),
            Text('Datum: $dateStr'),

            const SizedBox(height: 14),
            const Text(
              'Knjige:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(bookLines),
            const SizedBox(height: 14),
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _cancelOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.96),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OTKAŽI',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else if (order.paymentStatus == 2)
              const Text(
                'Online plaćene narudžbe nije moguće otkazati putem aplikacije.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                ),
              )
            else if (order.orderStatus == 2)
              const Text(
                'Završenu narudžbu nije moguće otkazati.',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              )
            else if (order.orderStatus == 3)
              const Text(
                'Ova narudžba je već otkazana.',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}.';
  }

}