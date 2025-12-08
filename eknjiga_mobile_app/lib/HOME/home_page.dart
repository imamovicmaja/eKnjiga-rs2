import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'genre_screen.dart';
import './../BOOKS/books_page.dart';
import './../MESSAGES/messages_page.dart';
import './../SETTINGS/settings_page.dart';
import 'package:eknjiga/SHOP/shop_page.dart';

import '../models/book.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'book_details_page.dart';

import 'cart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      final recommended =
          await ApiService.fetchRecommendedBooks(categoryId: categoryId);
      final allBooks =
          await ApiService.fetchBooks(categoryId: categoryId);

      List<Book> newBooks = [];
      if (categoryId == null) {
        newBooks = await ApiService.fetchNewBooks();
      }

      setState(() {
        _recommended = recommended;
        _newBooks = newBooks;
        _allBooks = allBooks;
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 212, 217, 246),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('eKnjiga', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _selectedCategory = null;
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
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
        padding: const EdgeInsets.only(top: 10),
        child: _buildBody(),
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
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
              break;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Greška pri dohvatu podataka',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRecommended = _filterBooks(_recommended);
    final filteredNew = _filterBooks(_newBooks);
    final filteredAll = _filterBooks(_allBooks);

    return ListView(
      children: [
        if (_selectedCategory != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Odabrani žanr: ${_selectedCategory!.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        if (_showSearchBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                onChanged:
                    (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  hintText: 'Pretraži',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

        sectionTitle('Preporučeno'),
        bookCarousel(filteredRecommended),

        if (_selectedCategory == null) ...[
          sectionTitle('Novo u prodaji'),
          bookCarousel(filteredNew),
        ],

        sectionTitle('Sve knjige'),
        bookCarousel(filteredAll),
        const SizedBox(height: 16),
      ],
    );
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

  Widget bookCarousel(List<Book> books) {
    if (books.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('Trenutno nema knjiga za prikaz.')),
      );
    }

    const double cardWidth = 140;
    const double imageHeight = 170;

    return SizedBox(
      height: imageHeight + 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailsPage(book: book),
                  ),
                );
              },
              child: Hero(
                tag: 'book-cover-${book.id}',
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
    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _bookCover(book, height: imageHeight, width: cardWidth),
          ),
          const SizedBox(height: 8),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            book.authors.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }
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
    return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
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
