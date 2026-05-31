import 'package:flutter/material.dart';
import '../HOME/cart.dart';
import '../SHOP/shop_page.dart';
import '../models/book.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class SelectFormatPage extends StatefulWidget {
  final Book book;

  const SelectFormatPage({
    super.key,
    required this.book,
  });

  @override
  State<SelectFormatPage> createState() => _SelectFormatPageState();
}

class _SelectFormatPageState extends State<SelectFormatPage> {
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

  final ApiService _apiService = ApiService();

  String? selectedFormat;
  bool _isCheckingPdfOwnership = true;
  bool _alreadyOwnsPdf = false;

  bool get _isPdf => selectedFormat == 'pdf';
  bool get _isHardCopy => selectedFormat == 'hard';

  @override
  void initState() {
    super.initState();
    _loadPdfOwnership();
  }

  Future<void> _loadPdfOwnership() async {
    try {
      final owned = await ApiService.hasPurchasedPdf(widget.book.id);

      if (!mounted) return;
      setState(() {
        _alreadyOwnsPdf = owned;
        _isCheckingPdfOwnership = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alreadyOwnsPdf = false;
        _isCheckingPdfOwnership = false;
      });
    }
  }

  void _handleFormatTap(String value) {
    if (value == 'pdf' && _alreadyOwnsPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF verzija ove knjige je već kupljena.'),
        ),
      );
      return;
    }

    setState(() {
      selectedFormat = value;
    });
  }

  void _addToCart() {
    final book = widget.book;

    if (selectedFormat == null) return;

    if (_isPdf && _alreadyOwnsPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF verzija ove knjige je već kupljena.'),
        ),
      );
      return;
    }

    Cart.I.add(
      CartItem(
        bookId: book.id,
        name: book.name,
        authors: book.authors,
        coverImage: book.coverImage,
        price: book.price,
        isPdfPurchase: _isPdf,
        quantity: 1,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShopPage(),
      ),
    );
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
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Odabir formata',
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: 125,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      width: 125,
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 44,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    width: 125,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.menu_book,
                                      size: 44,
                                      color: Colors.black45,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            book.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.authors.join(', '),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _formatButton(
                                  value: 'hard',
                                  label: 'Hard copy',
                                  isSelected: _isHardCopy,
                                  isDisabled: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _formatButton(
                                  value: 'pdf',
                                  label: _isCheckingPdfOwnership
                                      ? 'PDF...'
                                      : (_alreadyOwnsPdf ? 'Već kupljeno' : 'PDF'),
                                  isSelected: _isPdf,
                                  isDisabled: _alreadyOwnsPdf,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedFormat == null ||
                            (_isPdf && _alreadyOwnsPdf)
                        ? null
                        : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF96A6DA),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      (_isPdf && _alreadyOwnsPdf)
                          ? 'VEĆ KUPLJENO'
                          : 'DODAJ U KORPU',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

  Widget _formatButton({
    required String value,
    required String label,
    required bool isSelected,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: () => _handleFormatTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade300
              : isSelected
                  ? const Color(0xFF96A6DA)
                  : Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.black.withOpacity(0.10)
                : Colors.white.withOpacity(0.30),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.black45 : Colors.black87,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}