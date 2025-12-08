import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../HOME/pdf_viwer_page.dart';
import 'package:eknjiga/models/book.dart';
import 'package:eknjiga/services/api_service.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;

  const BookDetailsPage({super.key, required this.book});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  double _userRating = 0;
  bool _submitting = false;
  int? _existingReviewId;

  @override
  void initState() {
    super.initState();
    _loadUserReview();
  }

  Future<void> _loadUserReview() async {
    final userId = ApiService.userID;
    if (userId == null) {
      return;
    }

    try {
      final result = await ApiService.fetchUserReview(
        bookId: widget.book.id
      );

      if (!mounted || result == null) return;

      setState(() {
        _existingReviewId = result.id;
        _userRating = result.rating;
      });
    } catch (e) {
      debugPrint('Greška pri dohvaćanju recenzije: $e');
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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morate biti prijavljeni da ostavite recenziju.')),
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

        final result = await ApiService.fetchUserReview(
          bookId: widget.book.id
        );

        if (result != null && mounted) {
          setState(() {
            _existingReviewId = result.id;
            _userRating = result.rating;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hvala na recenziji ($_userRating ⭐)!'),
          ),
        );
      } else {
        await ApiService.updateReview(
          reviewId: _existingReviewId!,
          rating: _userRating,
          bookId: widget.book.id
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recenzija izmijenjena ($_userRating ⭐)!'),
          ),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Moja recenzija",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isFilled = _userRating >= starIndex;
                      return IconButton(
                        icon: Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _userRating = starIndex.toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  if (_userRating > 0)
                    Text(
                      'Odabrali ste: $_userRating ⭐',
                      style: const TextStyle(fontSize: 14),
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _existingReviewId == null
                                  ? 'Pošalji recenziju'
                                  : 'Izmijeni recenziju',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () {
                        final pdf = book.pdfFileBase64;
                        if (pdf != null && pdf.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerPage(pdfBase64: pdf),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF nije dostupan.')),
                          );
                        }
                      },
                      child: const Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
