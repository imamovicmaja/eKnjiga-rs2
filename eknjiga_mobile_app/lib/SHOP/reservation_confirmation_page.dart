import 'package:flutter/material.dart';
import '../HOME/reservation_cart.dart';
import '../SHOP/shop_page.dart';
import '../models/book.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../widgets/book_image.dart';

class ReservationConfirmationPage extends StatefulWidget {
  final Book book;

  const ReservationConfirmationPage({
    super.key,
    required this.book,
  });

  @override
  State<ReservationConfirmationPage> createState() =>
      _ReservationConfirmationPageState();
}

class _ReservationConfirmationPageState
    extends State<ReservationConfirmationPage> {
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

  bool busy = false;

  DateTime get createdAt => DateTime.now();
  DateTime get expiresAt => createdAt.add(const Duration(days: 2));

  String get pickupAddress =>
      'Poslovnica eKnjiga, Zmaja od Bosne 12, Sarajevo';

  double get total => widget.book.price;

  String _price(double value) => '${value.toStringAsFixed(2)} KM';

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}.';
  }

  Future<void> _addToReservations() async {
    setState(() => busy = true);

    try {
      ReservationCart.I.add(
        CartItem(
          bookId: widget.book.id,
          name: widget.book.name,
          authors: widget.book.authors,
          coverImage: widget.book.coverImage,
          price: widget.book.price,
          isPdfPurchase: false,
          quantity: 1,
          createdAt: createdAt,
          pickupAddress: pickupAddress,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Knjiga je dodana u rezervacije.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShopPage()),
      );
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
    final book = widget.book;
    final imageUrl = ApiService.getImageUrl(book.coverImage);

    return Scaffold(
      backgroundColor: const Color(0xFFD4D8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4D8F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Potvrda rezervacije',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bookCard(book, imageUrl),
                          const SizedBox(height: 18),
                          _summarySection(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : _addToReservations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96A6DA),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'DODAJ U REZERVACIJE',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookCard(Book book, String imageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: imageUrl.isNotEmpty
                ? BookImage(
                    url: imageUrl,
                    width: 100,
                    height: 145,
                    borderRadius: 22,
                  )
                : Container(
                    width: 100,
                    height: 145,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.book),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.authors.join(', '),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cijena: ${_price(total)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          _infoBlock(
            'Datum isteka roka za plaćanje i/ili preuzimanje:',
            _formatDate(expiresAt),
          ),
          const SizedBox(height: 12),
          _infoBlock(
            'Adresa poslovnice za plaćanje i/ili preuzimanje:',
            pickupAddress,
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.2,
            height: 1.25,
            color: Colors.black.withOpacity(0.58),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.2,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}