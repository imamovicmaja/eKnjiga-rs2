import 'package:flutter/material.dart';

import 'genre_screen.dart';
import './../BOOKS/books_page.dart';
import './../MESSAGES/messages_page.dart';
import './../SETTINGS/settings_page.dart';
import 'package:eknjiga/SHOP/shop_page.dart';

import '../models/book.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../BOOKSDETAILS/book_details_page.dart';

import '../widgets/book_image.dart';
import 'cart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  bool _showSearchBar = false;
  String _searchQuery = '';

  List<Book> _recommended = [];
  List<Book> _newBooks = [];
  List<Book> _allBooks = [];

  Category? _selectedCategory;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({Category? category}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (category != null) {
        _selectedCategory = category;
      }
    });

    final int? categoryId = _selectedCategory?.id;

    try {
      if (categoryId == null) {
        final results = await Future.wait([
          ApiService.fetchRecommendedBooks(categoryId: categoryId),
          ApiService.fetchBooks(categoryId: categoryId),
          ApiService.fetchNewBooks(),
        ]);

        if (!mounted) return;

        setState(() {
          _recommended = results[0] as List<Book>;
          _allBooks = results[1] as List<Book>;
          _newBooks = results[2] as List<Book>;
          _isLoading = false;
        });
      } else {
        final results = await Future.wait([
          ApiService.fetchRecommendedBooks(categoryId: categoryId),
          ApiService.fetchBooks(categoryId: categoryId),
        ]);

        if (!mounted) return;

        setState(() {
          _recommended = results[0] as List<Book>;
          _allBooks = results[1] as List<Book>;
          _newBooks = [];
          _isLoading = false;
        });
      }
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

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(bookId: book.id),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BookPage()),
        );
        break;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4D8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4D8F3),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () async {
            final result = await Navigator.push<Category?>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GenreScreen(initialCategory: _selectedCategory),
              ),
            );

            if (!mounted) return;

            if (result is Category) {
              await _loadData(category: result);
            } else {
              setState(() {
                _selectedCategory = null;
              });
              await _loadData();
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'eKnjiga',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;

                if (!_showSearchBar) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _selectedCategory = null;
              _searchController.clear();
              _searchQuery = '';
              _loadData();
            },
          ),
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
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: _pageGradient,
        ),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        elevation: 8,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 30),
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
    return Center(child: Text(_error!));
  }

  final filteredRecommended = _filterBooks(_recommended);
  final filteredNew = _filterBooks(_newBooks);
  final filteredAll = _filterBooks(_allBooks);

  return Column(
    children: [
      if (_showSearchBar)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Pretraži knjige ili autore...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 16),
          children: [
            _sectionTitle('Preporučeno'),
            _bookCarousel(filteredRecommended),

            if (_selectedCategory == null) ...[
              _sectionTitle('Novo u prodaji'),
              _bookCarousel(filteredNew),
            ],

            _sectionTitle('Sve knjige'),
            _bookCarousel(filteredAll),
          ],
        ),
      ),
    ],
  );
}

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _bookCarousel(List<Book> books) {
    const double cardWidth = 135;
    const double imageHeight = 188;

    return SizedBox(
      height: 258,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final book = books[index];

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _openBook(book),
              child: _BookCard(
                book: book,
                cardWidth: cardWidth,
                imageHeight: imageHeight,
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
                  borderRadius: 24,
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
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
