import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../SHOP/shop_page.dart';
import '../HOME/cart.dart';
import '../models/favorites.dart';
import 'select_format_page.dart';
import '../SHOP/reservation_confirmation_page.dart';
import '../widgets/book_image.dart';

class BookDetailsPage extends StatefulWidget {
  final int bookId;

  const BookDetailsPage({super.key, required this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFD4D8F3),
      Color(0xFF8D9EDB),
      Color(0xFFB59C4A),
    ],
    stops: [0.0, 0.56, 1.0],
  );

  Book? book;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getBookById(widget.bookId);
      if (!mounted) return;

      setState(() {
        book = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD4D8F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFD4D8F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFD4D8F3),
          elevation: 0,
          title: const Text(
            'Greška',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: _pageGradient),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error ?? 'Greška pri učitavanju knjige',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final currentBook = book!;
    final imageUrl = ApiService.getImageUrl(currentBook.coverImage);

    return Scaffold(
      backgroundColor: const Color(0xFFD4D8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4D8F3),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          currentBook.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopPage()),
                  );
                },
              ),
              Positioned(
                right: 6,
                top: 6,
                child: ValueListenableBuilder<int>(
                  valueListenable: Cart.I.count,
                  builder: (_, value, __) {
                    if (value == 0) return const SizedBox();

                    return Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'book-cover-${currentBook.id}',
                        child: imageUrl.isNotEmpty
                            ? BookImage(
                                url: imageUrl,
                                height: 230,
                                width: 155,
                                borderRadius: 28,
                              )
                            : Container(
                                height: 230,
                                width: 155,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.menu_book,
                                  size: 52,
                                  color: Colors.black45,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentBook.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentBook.authors.join(', '),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentBook.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '(${currentBook.ratingCount})',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Opis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentBook.description.isNotEmpty
                                  ? currentBook.description
                                  : 'Opis nije dostupan.',
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Colors.black87,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReservationConfirmationPage(
                                book: currentBook,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF96A6DA),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'REZERVIŠI',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SelectFormatPage(book: currentBook),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.96),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          currentBook.price > 0
                              ? 'Dodaj u korpu • ${_price(currentBook.price)}'
                              : 'Dodaj u korpu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _price(double value) => '${value.toStringAsFixed(2)} KM';