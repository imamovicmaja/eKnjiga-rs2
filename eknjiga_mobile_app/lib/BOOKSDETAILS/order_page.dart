import 'package:flutter/material.dart';
import '../HOME/pdf_viewer_page.dart';
import 'package:eknjiga/models/book.dart';
import 'package:eknjiga/services/api_service.dart';
import '../models/book.dart';
import '../HOME/cart.dart';
import '../models/favorites.dart';
import '../SHOP/shop_page.dart';

class OrderPage extends StatefulWidget {
  final Book book;
  final String heroTag;

  const OrderPage({super.key, required this.book, required this.heroTag});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD4D8F3), Color(0xFF8D9EDB), Color(0xFFB59C4A)],
    stops: [0.0, 0.56, 1.0],
  );

  double _userRating = 0;
  bool _submitting = false;
  int? _existingReviewId;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadUserReview();
    _loadFavorite();
  }

  Future<void> _loadUserReview() async {
    final userId = ApiService.userID;
    if (userId == 0) return;

    try {
      final result = await ApiService.fetchUserReview(bookId: widget.book.id);

      if (!mounted || result == null) return;

      setState(() {
        _existingReviewId = result.id;
        _userRating = result.rating;
      });
    } catch (e) {
      debugPrint('Greška pri dohvaćanju recenzije: $e');
    }
  }

  Future<void> _loadFavorite() async {
    final userId = ApiService.userID;
    if (userId == 0) return;

    try {
      final isFav = await ApiService.getFavorite(widget.book.id);

      if (!mounted) return;

      setState(() {
        _isFavorite = isFav;
      });
    } catch (e) {
      debugPrint('Greška pri dohvaćanju favorita: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite broj zvjezdica.')),
      );
      return;
    }

    final userId = ApiService.userID;
    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Morate biti prijavljeni da ostavite recenziju.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      if (_existingReviewId == null) {
        await ApiService.createReview(
          rating: _userRating,
          bookId: widget.book.id,
        );

        final result = await ApiService.fetchUserReview(bookId: widget.book.id);

        if (result != null && mounted) {
          setState(() {
            _existingReviewId = result.id;
            _userRating = result.rating;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hvala na recenziji ($_userRating ⭐)!')),
        );
      } else {
        await ApiService.updateReview(
          reviewId: _existingReviewId!,
          rating: _userRating,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recenzija izmijenjena ($_userRating ⭐)!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri slanju recenzije: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final imageUrl = ApiService.getImageUrl(book.coverImage);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.black,
            ),
            onPressed: () async {
              final newValue = !_isFavorite;

              setState(() {
                _isFavorite = newValue;
              });

              try {
                await ApiService.setFavorite(book.id, newValue);

                if (newValue) {
                  Favorites.I.add(book);
                } else {
                  Favorites.I.remove(book);
                }
              } catch (e) {
                setState(() {
                  _isFavorite = !newValue;
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Greška: $e')));
              }
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Hero(
                          tag: widget.heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox(
                              height: 250,
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 34,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.white,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.authors.join(', '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Opis",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.description.isNotEmpty
                              ? book.description
                              : 'Opis nije dostupan.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "O autoru",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.authors.isNotEmpty
                              ? book.authors.join(', ')
                              : 'Podaci o autoru nisu dostupni.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Moja recenzija",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = _userRating >= starIndex;
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isFilled ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _userRating = starIndex.toDouble();
                                });
                              },
                            );
                          }),
                        ),
                        if (_userRating > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Odabrali ste: $_userRating ⭐',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96A6DA),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _submitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                            : Text(
                              _existingReviewId == null
                                  ? 'Pošalji recenziju'
                                  : 'Izmijeni recenziju',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      try {
                        final bytes = await ApiService.getBookPdf(book.id);

                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PdfViewerPage(
                                  bytes: bytes,
                                  title: book.name,
                                ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        String message = 'Došlo je do greške.';

                        if (e.toString().contains('NOT_PAID')) {
                          message = 'Plaćanje još nije evidentirano.';
                        } else if (e.toString().contains('NO_ACCESS')) {
                          message = 'Nemate pristup ovoj knjizi.';
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}
