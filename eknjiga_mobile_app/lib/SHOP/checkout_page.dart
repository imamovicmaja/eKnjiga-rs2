import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/api_service.dart';
import '../HOME/cart.dart';

class CheckoutPage extends StatefulWidget {
  final List<Book> books;

  const CheckoutPage({super.key, required this.books});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool busy = false;

  late List<_CheckoutItem> _items;

  @override
  void initState() {
    super.initState();

    final allCartItems = Cart.I.items;
    final List<_CheckoutItem> temp = [];

    for (final book in widget.books) {
      final count = allCartItems.where((b) => b.id == book.id).length;
      final qty = count == 0 ? 1 : count;
      temp.add(_CheckoutItem(book: book, qty: qty));
    }

    _items = temp;
  }

  double get total =>
      _items.fold(0, (sum, item) => sum + item.book.price * item.qty);

  Future<void> _confirm() async {

    final validItems = _items.where((i) => i.qty > 0).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nema stavki za kupovinu.')),
      );
      return;
    }

    setState(() => busy = true);
    try {
      await ApiService.createOrder(
        type: 0,
        totalPrice: total,
        orderItems: validItems
            .map(
              (i) => {
                "bookId": i.book.id,
                "quantity": i.qty,
                "unitPrice": i.book.price,
              },
            )
            .toList(),
      );

      for (final item in validItems) {
        for (var i = 0; i < item.qty; i++) {
          Cart.I.remove(item.book);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupovina završena!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const topColor = Color.fromARGB(255, 212, 217, 246);
    const midColor = Color.fromARGB(255, 141, 158, 219);
    const bottomColor = Color.fromARGB(255, 181, 156, 74);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: topColor,
        elevation: 0,
        title: const Text('Potvrda kupovine'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _items.isEmpty
                        ? const Center(
                            child: Text('Korpa je prazna.'),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 20, thickness: 0.5),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final b = item.book;

                              Uint8List? coverBytes;
                              final b64 = b.coverImageBase64;
                              if (b64 != null && b64.isNotEmpty) {
                                try {
                                  coverBytes =
                                      base64Decode(b64.split(',').last);
                                } catch (_) {}
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: coverBytes != null
                                        ? Image.memory(
                                            coverBytes,
                                            width: 70,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 70,
                                            height: 100,
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.book,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b.authors.join(', '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Cijena: ${_price(b.price)}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text('Količina:'),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (item.qty > 1) {
                                                    final oldQty = item.qty;
                                                    item.qty--;
                                                    final diff =
                                                        oldQty - item.qty;
                                                    for (var i = 0;
                                                        i < diff;
                                                        i++) {
                                                      Cart.I
                                                          .remove(item.book);
                                                    }
                                                  } else {
                                                    Cart.I.remove(item.book);
                                                    _items.removeAt(index);
                                                  }
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                            ),
                                            Text(
                                              item.qty.toString(),
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  final oldQty = item.qty;
                                                  item.qty++;
                                                  final diff =
                                                      item.qty - oldQty;
                                                  for (var i = 0;
                                                      i < diff;
                                                      i++) {
                                                    Cart.I.add(item.book);
                                                  }
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 20,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Ukupno: ${_price(b.price * item.qty)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ukupno za naplatu:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _price(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy || _items.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kupi sada'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _price(double p) =>
      p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2) + ' KM';
}

class _CheckoutItem {
  final Book book;
  int qty;

  _CheckoutItem({required this.book, required this.qty});
}
