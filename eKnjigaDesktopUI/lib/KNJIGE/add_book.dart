import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/author.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../dialog/error_dialog.dart';

void addBook(
  BuildContext context,
  VoidCallback refreshBooks, {
  Map<String, dynamic>? initialData,
}) {
  final nameController =
      TextEditingController(text: initialData?['name']?.toString() ?? '');
  final descriptionController =
      TextEditingController(text: initialData?['description']?.toString() ?? '');
  final priceController = TextEditingController(
    text: initialData?['price']?.toString() ?? '',
  );

  final List<int> selectedAuthorIds =
      List<int>.from(initialData?['authorIds'] ?? []);
  final List<int> selectedCategoryIds =
      List<int>.from(initialData?['categoryIds'] ?? []);

  List<Author> availableAuthors = [];
  List<Category> availableCategories = [];

  Uint8List? selectedCoverBytes;
  Uint8List? selectedPdfBytes;

  String? selectedCoverFileName;
  String? selectedPdfFileName;

  String? nameError;
  String? priceError;
  String? authorError;
  String? categoryError;

  final String? existingCoverPath = _readInitialCoverPath(initialData);
  final bool hadPdfInitially =
      initialData?['pdfFile'] != null ||
      initialData?['pdfPath'] != null ||
      initialData?['pdfUrl'] != null;

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickCoverImage() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            );

            if (result == null || result.files.isEmpty) return;

            final file = result.files.first;
            if (file.bytes == null) {
              errorDialog(context, 'Slika nije učitana. Pokušaj ponovo.');
              return;
            }

            setState(() {
              selectedCoverBytes = file.bytes;
              selectedCoverFileName = file.name;
            });
          }

          Future<void> pickPdfFile() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              withData: true,
            );

            if (result == null || result.files.isEmpty) return;

            final file = result.files.first;
            if (file.bytes == null) {
              errorDialog(context, 'PDF nije učitan. Pokušaj ponovo.');
              return;
            }

            setState(() {
              selectedPdfBytes = file.bytes;
              selectedPdfFileName = file.name;
            });
          }

          Future<void> saveBook() async {
            setState(() {
              nameError = null;
              priceError = null;
              authorError = null;
              categoryError = null;
            });

            bool hasError = false;

            final name = nameController.text.trim();
            final description = descriptionController.text.trim();
            final price = double.tryParse(
              priceController.text.trim().replaceAll(',', '.'),
            );

            if (name.length < 3) {
              nameError = 'Naziv mora imati barem 3 karaktera.';
              hasError = true;
            }

            if (price == null || price <= 0) {
              priceError = 'Unesite validnu cijenu.';
              hasError = true;
            }

            if (selectedAuthorIds.isEmpty) {
              authorError = 'Odaberite najmanje jednog autora.';
              hasError = true;
            }

            if (selectedCategoryIds.isEmpty) {
              categoryError = 'Odaberite najmanje jednu kategoriju.';
              hasError = true;
            }

            if (hasError) {
              setState(() {});
              return;
            }

            final bookData = <String, dynamic>{
              'name': name,
              'description': description,
              'price': price,
              'authorIds': selectedAuthorIds,
              'categoryIds': selectedCategoryIds,
            };

            try {
              int bookId;

              if (initialData == null) {
                final createdBook = await ApiService.createBook(bookData);

                if (createdBook.id != null) {
                  bookId = int.parse(createdBook.id.toString());
                } else {
                  throw Exception(
                    'Knjiga je kreirana, ali ID nije vraćen iz API-ja.',
                  );
                }
              } else {
                bookId = int.parse(initialData['id'].toString());

                await ApiService.updateBook(
                  bookId,
                  {
                    'id': bookId,
                    ...bookData,
                  },
                );
              }

              if (selectedCoverBytes != null && selectedCoverFileName != null) {
                await ApiService.uploadBookCover(
                  bookId,
                  selectedCoverBytes!,
                  selectedCoverFileName!,
                );
              }

              if (selectedPdfBytes != null && selectedPdfFileName != null) {
                await ApiService.uploadBookPdf(
                  bookId,
                  selectedPdfBytes!,
                  selectedPdfFileName!,
                );
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              refreshBooks();
            } catch (e) {
              if (!context.mounted) return;
              errorDialog(
                context,
                e.toString().replaceFirst('Exception: ', ''),
              );
            }
          }

          return AlertDialog(
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
                  'Knjiga',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Naziv',
                        errorText: nameError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Opis'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cijena',
                        errorText: priceError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<List<Author>>(
                      future: ApiService.fetchAuthors(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Greška pri učitavanju autora.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        availableAuthors = snapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Autori',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableAuthors.map((author) {
                                final isSelected =
                                    selectedAuthorIds.contains(author.id);

                                return FilterChip(
                                  label: Text(
                                    '${author.firstName} ${author.lastName}',
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedAuthorIds.remove(author.id);
                                      } else {
                                        selectedAuthorIds.add(author.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (authorError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                authorError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    FutureBuilder<List<Category>>(
                      future: ApiService.fetchCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Greška pri učitavanju kategorija.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        availableCategories = snapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategorije',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableCategories.map((cat) {
                                final isSelected =
                                    selectedCategoryIds.contains(cat.id);

                                return FilterChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedCategoryIds.remove(cat.id);
                                      } else {
                                        selectedCategoryIds.add(cat.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (categoryError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                categoryError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    if (selectedCoverBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          selectedCoverBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (existingCoverPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _buildFullImageUrl(existingCoverPath),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Text('Nije moguće učitati naslovnicu'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                        (selectedCoverBytes != null || existingCoverPath != null)
                            ? 'Zamijeni naslovnicu'
                            : 'Dodaj naslovnicu',
                      ),
                      onPressed: pickCoverImage,
                    ),

                    if (selectedCoverFileName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Odabrana slika: $selectedCoverFileName',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 14),

                    if (hadPdfInitially && selectedPdfFileName == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'PDF već postoji za ovu knjigu.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(
                        (selectedPdfBytes != null || hadPdfInitially)
                            ? 'Zamijeni PDF'
                            : 'Dodaj PDF',
                      ),
                      onPressed: pickPdfFile,
                    ),

                    if (selectedPdfFileName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Odabrani PDF: $selectedPdfFileName',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.shade300,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Otkaži'),
              ),
              ElevatedButton(
                onPressed: () {
                  saveBook();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.black,
                ),
                child: Text(initialData == null ? 'Dodaj' : 'Sačuvaj'),
              ),
            ],
          );
        },
      );
    },
  );
}

String? _readInitialCoverPath(Map<String, dynamic>? data) {
  if (data == null) return null;

  final value = data['coverImage'];
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return text;
}

String _buildFullImageUrl(String coverImage) {
  return ApiService.getImageUrl(coverImage);
}