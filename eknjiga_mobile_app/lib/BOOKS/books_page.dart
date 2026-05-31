import 'package:flutter/material.dart';

import './../HOME/home_page.dart';
import './../SHOP/shop_page.dart';
import './../MESSAGES/messages_page.dart';
import './../SETTINGS/settings_page.dart';
import '../BOOKSDETAILS/order_page.dart';

import '../models/book.dart';
import '../models/favorites.dart';
import '../services/api_service.dart';
import '../widgets/book_image.dart';


class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
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

  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  String _searchQuery = '';

  List<Book> _userBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserBooks();
  }

  Future<void> _loadUserBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await ApiService.fetchUserBooks();

      if (!mounted) return;

      setState(() {
        _userBooks = books;
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(List<Book> books) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return books;

    return books.where((b) {
      final name = b.name.toLowerCase();
      final authors = b.authors.join(' ').toLowerCase();
      return name.contains(q) || authors.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4D8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4D8F3),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'eKnjiga',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadUserBooks,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: _pageGradient,
        ),
        padding: const EdgeInsets.only(top: 10),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
              break;
            case 1:
              return;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ShopPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MessagesPage()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
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
            icon: Icon(Icons.settings, size: 32),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Greška pri dohvatu podataka',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadUserBooks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _filterBooks(_userBooks);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (_showSearchBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() => _searchQuery = v);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  hintText: 'Pretraži',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (Favorites.I.items.isNotEmpty) ...[
            _sectionTitle('Omiljene'),
            _bookCarousel(Favorites.I.items),
            const SizedBox(height: 12),
          ],
        _sectionTitle('Moje knjige'),
        _bookCarousel(filtered),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _bookCarousel(List<Book> books) {
    if (books.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('Nema knjiga')),
      );
    }

    const double cardWidth = 140;
    const double imageHeight = 170;

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          final heroTag = 'book-cover-${book.id}-$index';

          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(
                      book: book,
                      heroTag: heroTag,
                    ),
                  ),
                );

                if (!mounted) return;
                await _loadUserBooks();
              },
              child: Hero(
                tag: heroTag,
                child: _BookCard(
                  book: book,
                  cardWidth: cardWidth,
                  imageHeight: imageHeight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final double cardWidth;
  final double imageHeight;

  const _BookCard({
    required this.book,
    required this.cardWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.getImageUrl(book.coverImage);

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageUrl.isNotEmpty
            ? BookImage(
                url: imageUrl,
                height: imageHeight,
                width: cardWidth,
                borderRadius: 16,
              )
            : Container(
                height: imageHeight,
                width: cardWidth,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.menu_book, size: 40),
              ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Text(
              book.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.1,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: Text(
              book.authors.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}