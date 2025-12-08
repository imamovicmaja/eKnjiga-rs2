import 'dart:convert';
import 'package:flutter/material.dart';

import './../Home/home_page.dart';
import './../BOOKS/books_page.dart';
import './../MESSAGES/messages_page.dart';
import './../SETTINGS/settings_page.dart';

import '../HOME/cart.dart';
import '../services/api_service.dart';
import '../models/book.dart';
import '../models/order.dart';
import 'checkout_page.dart';

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
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = Cart.I.items;
    final uniqueCartItems = _uniqueBooks(cartItems);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 212, 217, 246),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('eKnjiga', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle('Moja korpa'),

                          uniqueCartItems.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Korpa je prazna'),
                                )
                              : horizontalBookList(uniqueCartItems),

                          if (uniqueCartItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final changed = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          books: uniqueCartItems,
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Završi kupovinu'),
                                ),
                              ),
                            ),
                          ],

                          sectionTitle('Moje narudžbe i rezervacije'),
                          const SizedBox(height: 12),
                          ..._orderItemList(_orders),
                          const SizedBox(height: 10),
                        ],
                      ),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ShopPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesPage()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 32), label: ""),
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
            icon: Icon(Icons.settings, size: 32), label: ""),
        ],
      ),
    );
  }

  List<Book> _uniqueBooks(List<Book> books) {
    final map = <dynamic, Book>{};
    for (final b in books) {
      map[b.id] = b;
    }
    return map.values.toList();
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

  Widget horizontalBookList(List<Book> books) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          Widget cover;
          final b64 = book.coverImageBase64;
          if (b64 != null && b64.isNotEmpty) {
            try {
              final bytes = base64Decode(b64.split(',').last);
              cover = Image.memory(bytes, height: 150, fit: BoxFit.cover);
            } catch (_) {
              cover = Container(
                height: 150,
                color: Colors.white,
                child: const Icon(Icons.book, size: 40),
              );
            }
          } else {
            cover = Container(
              height: 150,
              color: Colors.white,
              child: const Icon(Icons.book, size: 40),
            );
          }

          return InkWell(
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutPage(books: [book]),
                ),
              );
              if (changed == true) {
                await _loadOrders();
                setState(() {});
              }
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: cover,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    book.authors.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      iconSize: 18,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => Cart.I.remove(book));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Uklonjeno iz korpe: ${book.name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static List<Widget> _orderItemList(List<OrderResponse> orders) {
    return orders
        .map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _orderItem(order),
          ),
        )
        .toList();
  }

  static Widget _orderItem(OrderResponse order) {
    final typeText = order.type == 0 ? 'Kupovina' : 'Rezervacija';
    final d = order.orderDate.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr =
        '${two(d.day)}.${two(d.month)}.${d.year}. ${two(d.hour)}:${two(d.minute)}';

    final totalStr = order.totalPrice.toStringAsFixed(2);

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

    final bookLines = order.orderItems
        .map((oi) =>
            '• ${oi.book?.name ?? "Nepoznata knjiga"} (x${oi.quantity})')
        .join('\n');

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
                  totalStr + " KM",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              "Status: ${_statusText(order.orderStatus)}",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Datum: $dateStr',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Knjige:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xfff7f7f7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bookLines,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
