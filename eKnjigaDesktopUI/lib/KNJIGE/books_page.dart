import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../FORUM/forum_page.dart';
import '../KORISNICI/user_page.dart';
import '../NARUDZBE/order_page.dart';
import '../LOGIN/login_page.dart';

import './add_book.dart';
import './add_category.dart';
import './add_author.dart';

import '../models/book.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  String selectedSidebar = "KNJIGE";

  final TextEditingController _bookNameCtrl = TextEditingController();
  int? _selectedBookCategoryId;

  final TextEditingController _authorFirstNameCtrl = TextEditingController();
  final TextEditingController _authorLastNameCtrl = TextEditingController();

  final TextEditingController _categoryNameCtrl = TextEditingController();

  final TextEditingController _reviewRatingCtrl = TextEditingController();
  int? _selectedReviewBookId;
  int? _selectedReviewUserId;

  Timer? _debounce;
  static const _debounceMs = 450;

  List<Book> books = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> authors = [];
  List<Review> reviews = [];
  List<User> reviewUsers = [];

  bool _loadingBooks = false;
  bool _loadingCategories = false;
  bool _loadingAuthors = false;
  bool _loadingReviews = false;
  bool _loadingReviewUsers = false;

  @override
  void initState() {
    super.initState();
    loadCategoriesFromApi();
    loadAuthorsFromApi();
    loadReviewUsersFromApi();
    loadReviewsFromApi();
    loadBooksFromApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _bookNameCtrl.dispose();

    _authorFirstNameCtrl.dispose();
    _authorLastNameCtrl.dispose();

    _categoryNameCtrl.dispose();

    _reviewRatingCtrl.dispose();

    super.dispose();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ---------------------- BOOKS ----------------------

  Future<void> loadBooksFromApi({
    String? name,
    int? categoryId,
  }) async {
    try {
      if (mounted) setState(() => _loadingBooks = true);

      final fetched = await ApiService.fetchBooks(
        name: name,
        categoryId: categoryId,
      );

      if (!mounted) return;
      setState(() {
        books = fetched;
      });
    } catch (e) {
      debugPrint("Greška pri učitavanju knjiga: $e");
    } finally {
      if (mounted) setState(() => _loadingBooks = false);
    }
  }

  void _onBookFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      final name = _bookNameCtrl.text.trim();
      final categoryId = _selectedBookCategoryId;

      final allEmpty = name.isEmpty && categoryId == null;

      if (allEmpty) {
        loadBooksFromApi();
      } else {
        loadBooksFromApi(
          name: name.isEmpty ? null : name,
          categoryId: categoryId,
        );
      }
    });
  }

  // ---------------------- CATEGORIES ----------------------

  Future<void> loadCategoriesFromApi({String? name}) async {
    try {
      if (mounted) setState(() => _loadingCategories = true);

      final fetched = await ApiService.fetchCategories(name: name);

      if (mounted) {
        setState(() {
          categories = fetched
              .map((c) => {
                    'id': c.id,
                    'name': c.name,
                    'bookIds': [],
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Greška pri dohvaćanju kategorija: $e");
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _onCategoryFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      final name = _categoryNameCtrl.text.trim();
      if (name.isEmpty) {
        loadCategoriesFromApi();
      } else {
        loadCategoriesFromApi(name: name);
      }
    });
  }

  // ---------------------- AUTHORS ----------------------

  Future<void> loadAuthorsFromApi({String? firstName, String? lastName}) async {
    try {
      if (mounted) setState(() => _loadingAuthors = true);

      final fetched = await ApiService.fetchAuthors(
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;
      setState(() {
        authors = fetched
            .map((a) => {
                  'id': a.id,
                  'firstName': a.firstName,
                  'lastName': a.lastName,
                  'birthDate': a.birthDate,
                  'deathDate': a.deathDate,
                  'description': a.description,
                  'books': a.books,
                })
            .toList();
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju autora: $e");
    } finally {
      if (mounted) setState(() => _loadingAuthors = false);
    }
  }

  void _onAuthorFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      final firstName = _authorFirstNameCtrl.text.trim();
      final lastName = _authorLastNameCtrl.text.trim();

      final allEmpty = firstName.isEmpty && lastName.isEmpty;
      if (allEmpty) {
        loadAuthorsFromApi();
      } else {
        loadAuthorsFromApi(
          firstName: firstName.isEmpty ? null : firstName,
          lastName: lastName.isEmpty ? null : lastName,
        );
      }
    });
  }

  // ---------------------- USERS FOR REVIEWS ----------------------

  Future<void> loadReviewUsersFromApi() async {
    try {
      if (mounted) setState(() => _loadingReviewUsers = true);

      final fetched = await ApiService.fetchUsers(
        includeTotalCount: false,
      );

      if (!mounted) return;
      setState(() {
        reviewUsers = fetched
            .map((m) => User(
                  id: m['id'],
                  firstName: m['name'],
                  lastName: '',
                  username: '',
                  email: m['email'],
                  isActive: true,
                ))
            .toList();
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju korisnika za recenzije: $e");
    } finally {
      if (mounted) setState(() => _loadingReviewUsers = false);
    }
  }

  // ---------------------- REVIEWS ----------------------

  Future<void> loadReviewsFromApi({
    int? bookId,
    int? userId,
    int? rating,
  }) async {
    try {
      if (mounted) setState(() => _loadingReviews = true);

      final fetched = await ApiService.fetchReviews(
        bookId: bookId,
        userId: userId,
        rating: rating,
      );

      if (!mounted) return;
      setState(() {
        reviews = fetched;
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju recenzija: $e");
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  void _onReviewFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      final ratingStr = _reviewRatingCtrl.text.trim();
      final rating = int.tryParse(ratingStr);

      final bookId = _selectedReviewBookId;
      final userId = _selectedReviewUserId;

      final allEmpty = (bookId == null) && (userId == null) && (rating == null);

      if (allEmpty) {
        loadReviewsFromApi();
      } else {
        loadReviewsFromApi(
          bookId: bookId,
          userId: userId,
          rating: rating,
        );
      }
    });
  }

  // ---------------------- PDF ----------------------

  Future<void> saveAndOpenPdf(String base64Data) async {
    final bytes = base64Decode(base64Data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/knjiga.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 212, 217, 246),
                  Color.fromARGB(255, 141, 158, 219),
                  Color.fromARGB(255, 181, 156, 74),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                color: Colors.white.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "eKnjiga",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(width: 50),
                        navTab("KORISNICI", context),
                        const SizedBox(width: 32),
                        navTab("KNJIGE", context, isActive: true),
                        const SizedBox(width: 32),
                        navTab("NARUDŽBE", context),
                        const SizedBox(width: 32),
                        navTab("FORUM", context),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 181, 156, 74),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Odjavi se"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // SIDEBAR
                    Container(
                      width: 180,
                      color: Colors.white.withOpacity(0.8),
                      padding: const EdgeInsets.only(top: 32, left: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sidebarOption("KNJIGE", Icons.menu_book),
                          const SizedBox(height: 24),
                          sidebarOption("AUTORI", Icons.person_outline),
                          const SizedBox(height: 24),
                          sidebarOption("KATEGORIJA", Icons.category),
                          const SizedBox(height: 24),
                          sidebarOption("RECENZIJA", Icons.rate_review),
                        ],
                      ),
                    ),

                    // MAIN CONTENT
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FILTER
                                if (selectedSidebar == "KNJIGE") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _filterField(
                                          label: "Naziv",
                                          controller: _bookNameCtrl,
                                          loading: _loadingBooks,
                                          onChanged: (_) =>
                                              _onBookFieldChanged(),
                                        ),
                                        SizedBox(
                                          width: 220,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: "Kategorija",
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                borderSide:
                                                    BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int?>(
                                                isExpanded: true,
                                                value:
                                                    _selectedBookCategoryId,
                                                hint: const Text(
                                                    "Sve kategorije"),
                                                items: [
                                                  const DropdownMenuItem<
                                                      int?>(
                                                    value: null,
                                                    child: Text(
                                                        "Sve kategorije"),
                                                  ),
                                                  ...categories.map(
                                                    (c) =>
                                                        DropdownMenuItem<
                                                            int?>(
                                                      value: c['id']
                                                          as int,
                                                      child: Text(
                                                          c['name']
                                                              .toString()),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedBookCategoryId =
                                                        value;
                                                  });
                                                  _onBookFieldChanged();
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            _bookNameCtrl.clear();
                                            setState(() {
                                              _selectedBookCategoryId =
                                                  null;
                                            });
                                            _onBookFieldChanged();
                                          },
                                          icon:
                                              const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (selectedSidebar ==
                                    "AUTORI") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _filterField(
                                          label: "Ime",
                                          controller:
                                              _authorFirstNameCtrl,
                                          loading: _loadingAuthors,
                                          onChanged: (_) =>
                                              _onAuthorFieldChanged(),
                                        ),
                                        _filterField(
                                          label: "Prezime",
                                          controller:
                                              _authorLastNameCtrl,
                                          loading: _loadingAuthors,
                                          onChanged: (_) =>
                                              _onAuthorFieldChanged(),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            _authorFirstNameCtrl.clear();
                                            _authorLastNameCtrl.clear();
                                            _onAuthorFieldChanged();
                                          },
                                          icon:
                                              const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (selectedSidebar ==
                                    "KATEGORIJA") ...[
                                  SizedBox(
                                    width: 300,
                                    child: TextField(
                                      controller: _categoryNameCtrl,
                                      onChanged: (_) =>
                                          _onCategoryFieldChanged(),
                                      decoration: InputDecoration(
                                        hintText:
                                            "Pretraži kategorije po nazivu...",
                                        prefixIcon:
                                            const Icon(Icons.search),
                                        suffixIcon: _loadingCategories
                                            ? const Padding(
                                                padding:
                                                    EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              )
                                            : (_categoryNameCtrl
                                                    .text.isEmpty
                                                ? null
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.clear),
                                                    onPressed: () {
                                                      _categoryNameCtrl
                                                          .clear();
                                                      _onCategoryFieldChanged();
                                                    },
                                                  )),
                                        filled: true,
                                        fillColor: Colors.white
                                            .withOpacity(0.9),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (selectedSidebar ==
                                    "RECENZIJA") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        // Book dropdown
                                        SizedBox(
                                          width: 220,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: "Knjiga",
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                borderSide:
                                                    BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int?>(
                                                isExpanded: true,
                                                value:
                                                    _selectedReviewBookId,
                                                hint: const Text(
                                                    "Sve knjige"),
                                                items: [
                                                  const DropdownMenuItem<
                                                      int?>(
                                                    value: null,
                                                    child: Text(
                                                        "Sve knjige"),
                                                  ),
                                                  ...books.map(
                                                    (b) =>
                                                        DropdownMenuItem<
                                                            int?>(
                                                      value: b.id,
                                                      child: Text(b.name),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedReviewBookId =
                                                        value;
                                                  });
                                                  _onReviewFieldChanged();
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        // User dropdown
                                        SizedBox(
                                          width: 220,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: "Korisnik",
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                borderSide:
                                                    BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child:
                                                  DropdownButton<int?>(
                                                isExpanded: true,
                                                value:
                                                    _selectedReviewUserId,
                                                hint: const Text(
                                                    "Svi korisnici"),
                                                items: [
                                                  const DropdownMenuItem<
                                                      int?>(
                                                    value: null,
                                                    child: Text(
                                                        "Svi korisnici"),
                                                  ),
                                                  ...reviewUsers.map(
                                                    (u) =>
                                                        DropdownMenuItem<
                                                            int?>(
                                                      value: u.id,
                                                      child: Text(
                                                        "${u.firstName} ${u.lastName}",
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedReviewUserId =
                                                        value;
                                                  });
                                                  _onReviewFieldChanged();
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Rating field
                                        _filterField(
                                          label: "Ocjena (1, 2, 3, 4, 5)",
                                          controller: _reviewRatingCtrl,
                                          keyboardType:
                                              TextInputType.number,
                                          loading: _loadingReviews,
                                          onChanged: (_) =>
                                              _onReviewFieldChanged(),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _selectedReviewBookId =
                                                  null;
                                              _selectedReviewUserId =
                                                  null;
                                            });
                                            _reviewRatingCtrl.clear();
                                            _onReviewFieldChanged();
                                          },
                                          icon:
                                              const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox.shrink(),
                                ],

                                if (selectedSidebar != "RECENZIJA")
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (selectedSidebar == "KNJIGE") {
                                        addBook(
                                          context,
                                          () => _onBookFieldChanged(),
                                        );
                                      } else if (selectedSidebar ==
                                          "AUTORI") {
                                        addAuthor(
                                          context,
                                          () =>
                                              _onAuthorFieldChanged(),
                                        );
                                      } else if (selectedSidebar ==
                                          "KATEGORIJA") {
                                        addCategory(
                                          context,
                                          () =>
                                              _onCategoryFieldChanged(),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("Dodaj"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            Expanded(child: _buildContent()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool loading = false,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged(controller.text);
                      },
                    )),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget sidebarOption(String label, IconData icon) {
    final bool isActive = selectedSidebar == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedSidebar = label;
        });
        if (label == "KNJIGE") {
          _onBookFieldChanged();
        } else if (label == "AUTORI") {
          _onAuthorFieldChanged();
        } else if (label == "KATEGORIJA") {
          _onCategoryFieldChanged();
        } else if (label == "RECENZIJA") {
          _onReviewFieldChanged();
        }
      },
      hoverColor: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey[700],
                backgroundColor: isActive
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedSidebar) {
      case "KNJIGE":
        return Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: books.isEmpty
                  ? (_loadingBooks
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : const Center(child: Text("Nema rezultata.")))
                  : ListView.builder(
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final hasCover = book.coverImageBase64 != null &&
                          book.coverImageBase64!.isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Row(
                                    children: const [
                                      Icon(
                                        Icons.menu_book,
                                        color: Color.fromARGB(255, 181, 156, 74),
                                        size: 30,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Detalji knjige",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: 400,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _infoRow("Naziv", book.name),
                                        _infoRow("Opis", book.description),
                                        _infoRow(
                                          "Cijena",
                                          "${book.price.toStringAsFixed(2)} KM",
                                        ),
                                        _infoRow(
                                          "Ocjena",
                                          "${book.rating.toStringAsFixed(1)} (${book.ratingCount} ocjena)",
                                        ),
                                        _infoRow(
                                          "Datum dodavanja",
                                          book.createdAt.toLocal().toString().split(" ")[0],
                                        ),
                                        if (book.coverImageBase64 != null &&
                                            book.coverImageBase64!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                base64Decode(book.coverImageBase64!),
                                                height: 180,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        if (book.pdfFileBase64 != null)
                                          ElevatedButton.icon(
                                            onPressed: () => saveAndOpenPdf(book.pdfFileBase64!),
                                            icon: const Icon(Icons.picture_as_pdf),
                                            label: const Text("Otvori PDF"),
                                          ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red.shade300,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text("Zatvori"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              height: hasCover ? 150 : 80,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  if (hasCover)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.memory(
                                        base64Decode(book.coverImageBase64!),
                                        width: 100,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.menu_book,
                                      color: Color.fromARGB(255, 181, 156, 74),
                                      size: 40,
                                    ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          book.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Autori: ${book.authors.join(', ')}",
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          addBook(
                                            context,
                                            () => _onBookFieldChanged(),
                                            initialData: {
                                              'id': book.id,
                                              'name': book.name,
                                              'description': book.description,
                                              'price': book.price,
                                              'authorIds': book.authorIds,
                                              'categoryIds': book.categoryIds,
                                              'coverImage': book.coverImageBase64,
                                              'pdfFile': book.pdfFileBase64
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Potvrda"),
                                              content: const Text(
                                                "Da li sigurno želiš obrisati knjigu?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, false),
                                                  child: const Text("Otkaži"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, true),
                                                  child: const Text("Obriši"),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              await ApiService.deleteBook(book.id);
                                              _onBookFieldChanged();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Knjiga obrisana"),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    e.toString().replaceFirst(
                                                          "Exception: ",
                                                          "",
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

      case "AUTORI":
        return Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: authors.isEmpty
                  ? (_loadingAuthors
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : const Center(child: Text("Nema rezultata.")))
                  : ListView.builder(
                      itemCount: authors.length,
                      itemBuilder: (context, index) {
                        final author = authors[index];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            onTap: () =>
                                showAuthorDetailsDialog(context, author),
                            leading: const Icon(
                              Icons.person_outline,
                              color:
                                  Color.fromARGB(255, 181, 156, 74),
                            ),
                            title: Text(
                              "${author['firstName']} ${author['lastName']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (author['birthDate'] != null)
                                  Text(
                                    "Rođen: ${formatAuthorDate(author['birthDate'])}",
                                  ),
                                if (author['deathDate'] != null)
                                  Text(
                                    "Preminuo: ${formatAuthorDate(author['deathDate'])}",
                                  ),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 12,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    addAuthor(
                                      context,
                                      () => _onAuthorFieldChanged(),
                                      initialData: author,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title:
                                            const Text("Potvrda"),
                                        content: const Text(
                                          "Da li sigurno želiš obrisati autora?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, false),
                                            child:
                                                const Text("Otkaži"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(
                                                    context, true),
                                            child:
                                                const Text("Obriši"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ApiService.deleteAuthor(
                                          author['id'],
                                        );
                                        _onAuthorFieldChanged();
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Autor obrisan",
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e
                                                  .toString()
                                                  .replaceFirst(
                                                    "Exception: ",
                                                    "",
                                                  ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

      case "KATEGORIJA":
        return Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: _loadingCategories
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : (categories.isEmpty
                      ? const Center(child: Text("Nema rezultata."))
                      : ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.category,
                                  color: Color.fromARGB(
                                      255, 181, 156, 74),
                                ),
                                title: Text(
                                  category['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 12,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        addCategory(
                                          context,
                                          () =>
                                              _onCategoryFieldChanged(),
                                          initialData: category,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              "Potvrda",
                                            ),
                                            content: const Text(
                                              "Da li sigurno želiš obrisati kategoriju?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                child: const Text(
                                                  "Otkaži",
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                child: const Text(
                                                  "Obriši",
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            await ApiService
                                                .deleteCategory(
                                              category['id'],
                                            );
                                            _onCategoryFieldChanged();
                                            ScaffoldMessenger.of(
                                                    context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Kategorija obrisana",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                                    context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  e
                                                      .toString()
                                                      .replaceFirst(
                                                        "Exception: ",
                                                        "",
                                                      ),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )),
            ),
          ],
        );

      case "RECENZIJA":
        return Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: reviews.isEmpty
                  ? (_loadingReviews
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : const Center(child: Text("Nema rezultata.")))
                  : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Card(
                          margin:
                              const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.rate_review,
                              color:
                                  Color.fromARGB(255, 181, 156, 74),
                            ),
                            title: Text(
                              "Ocjena: ${review.rating.toStringAsFixed(1)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (review.userFullName != null)
                                  Text(
                                    "Korisnik: ${review.userFullName}",
                                  ),
                                if (review.bookTitle != null)
                                  Text(
                                    "Knjiga: ${review.bookTitle}",
                                  ),
                                Text(
                                  "Datum: ${review.createdAt.toLocal().toString().split(' ')[0]}",
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Potvrda"),
                                    content: const Text(
                                      "Da li sigurno želiš obrisati recenziju?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, false),
                                        child: const Text("Otkaži"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, true),
                                        child: const Text("Obriši"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await ApiService.deleteReview(
                                      review.id,
                                    );
                                    _onReviewFieldChanged();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Recenzija obrisana",
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e
                                              .toString()
                                              .replaceFirst(
                                                "Exception: ",
                                                "",
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

      default:
        return const Center(child: Text("Odaberi stavku iz menija"));
    }
  }

  Widget navTab(String label, BuildContext context, {bool isActive = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (label == "KORISNICI") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const UserPage(),
              ),
            );
          } else if (label == "KNJIGE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BooksPage(),
              ),
            );
          } else if (label == "NARUDŽBE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const OrderPage(),
              ),
            );
          } else if (label == "FORUM") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ForumPage(),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? const Color.fromARGB(255, 181, 156, 74)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
