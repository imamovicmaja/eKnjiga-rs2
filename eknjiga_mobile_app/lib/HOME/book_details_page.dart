import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:eknjiga/models/book.dart';
import 'package:eknjiga/SHOP/shop_page.dart';
import '../services/api_service.dart';
import '../HOME/cart.dart';

class BookDetailsPage extends StatelessWidget {
  final Book book;

  const BookDetailsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: Cart.I.count,
            builder: (context, value, _) {
              final hasItems = value > 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopPage()),
                      );
                    },
                  ),
                  if (hasItems)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'book-cover-${book.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _bookCover(book, height: 250),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    book.authors.join(', '),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '(${book.ratingCount})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Opis",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.description.isNotEmpty
                        ? book.description
                        : 'Opis nije dostupan.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "O autoru",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authors.isNotEmpty
                        ? book.authors.join(', ')
                        : 'Podaci o autoru nisu dostupni.',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ApiService.createOrder(
                                  type: 1,
                                  totalPrice: 0,
                                  orderItems: [
                                    {
                                      "bookId": book.id,
                                      "quantity": 1,
                                      "unitPrice": book.price,
                                    },
                                  ],
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Knjiga uspješno rezervisana!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Greška: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                141,
                                158,
                                219,
                              ),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("REZERVIŠI"),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              Cart.I.add(book);
                              try {
                                // await ApiService.createOrder(
                                //   type: 0,
                                //   totalPrice: book.price,
                                //   orderItems: [
                                //     {
                                //       "bookId": book.id,
                                //       "quantity": 1,
                                //       "unitPrice": book.price,
                                //     },
                                //   ],
                                // );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Knjiga dodana u korpu '),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Greška: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              book.price > 0
                                  ? 'KUPI • ${_price(book.price)}'
                                  : 'KUPI',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _price(double p) =>
      p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2) + ' KM';

  Widget _bookCover(Book book, {double? height, double? width}) {
    final base64Str = book.coverImageBase64;
    if (base64Str == null || base64Str.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.bookmark, size: 40, color: Colors.black45),
        ),
      );
    }
    try {
      final cleaned =
          base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      final Uint8List bytes = base64Decode(cleaned);
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return Container(
        height: height,
        width: width,
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.black45),
        ),
      );
    }
  }
}
