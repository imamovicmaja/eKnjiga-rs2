import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class GenreScreen extends StatefulWidget {
  final Category? initialCategory;

  const GenreScreen({super.key, this.initialCategory});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  List<Category> categories = [];
  Category? selectedCategory;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final fetched = await ApiService.fetchCategories();
      setState(() {
        categories = fetched;
        if (widget.initialCategory != null) {
          selectedCategory = categories.firstWhere(
            (c) => c.id == widget.initialCategory!.id,
            orElse: () => widget.initialCategory!,
          );
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
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
        padding: const EdgeInsets.fromLTRB(30, 100, 30, 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ŽANROVI',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(child: _buildCategoryList()),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, selectedCategory);
                  },
                  child: const Text(
                    'Prikaži knjige za odabrani žanr',
                    style: TextStyle(letterSpacing: 1.2),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedCategory = null;
                    });
                    Navigator.pop(context, null);
                  },
                  child: const Text(
                    'Prikaži knjige za sve žanrove',
                    style: TextStyle(letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text('Greška pri dohvatu kategorija:\n$_error'),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 2, color: Colors.transparent),
      itemBuilder: (context, index) {
        final c = categories[index];

        return RadioListTile<Category>(
          value: c,
          groupValue: selectedCategory,
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
            });
          },
          title: Text(
            c.name,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          activeColor: Colors.black,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
