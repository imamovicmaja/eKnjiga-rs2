import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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
      TextEditingController(text: initialData?['name'] ?? '');
  final descriptionController =
      TextEditingController(text: initialData?['description'] ?? '');
  final priceController = TextEditingController(
    text: initialData?['price']?.toString() ?? '',
  );

  List<Author> availableAuthors = [];
  List<Category> availableCategories = [];

  List<int> selectedAuthorIds =
      List<int>.from(initialData?['authorIds'] ?? []);
  List<int> selectedCategoryIds =
      List<int>.from(initialData?['categoryIds'] ?? []);

  Uint8List? coverImage = initialData?['coverImage'] != null
      ? base64Decode(initialData!['coverImage'])
      : null;

  Uint8List? pdfFile;

  String? nameError, priceError, authorError, categoryError;

  final bool hadCoverInitially = initialData?['coverImage'] != null;
  final bool hadPdfInitially = initialData?['pdfFile'] != null;

  Future<void> openPdfFromBase64(BuildContext ctx, String base64Pdf) async {

    final bytes = base64Decode(base64Pdf);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/knjiga.pdf');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(
                Icons.menu_book,
                color: Color.fromARGB(255, 181, 156, 74),
                size: 30,
              ),
              SizedBox(width: 8),
              Text(
                "Knjiga",
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
                      labelText: "Naziv",
                      errorText: nameError,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Opis"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Cijena",
                      errorText: priceError,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<Author>>(
                    future: ApiService.fetchAuthors(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      availableAuthors = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Autori",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            children: availableAuthors.map((author) {
                              final isSelected =
                                  selectedAuthorIds.contains(author.id);
                              return FilterChip(
                                label: Text(
                                  "${author.firstName} ${author.lastName}",
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    isSelected
                                        ? selectedAuthorIds.remove(author.id)
                                        : selectedAuthorIds.add(author.id);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          if (authorError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                authorError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  FutureBuilder<List<Category>>(
                    future: ApiService.fetchCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      availableCategories = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kategorije",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            children: availableCategories
                                .map((Category cat) {
                                  final isSelected =
                                      selectedCategoryIds.contains(cat.id);
                                  return FilterChip(
                                    label: Text(cat.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        isSelected
                                            ? selectedCategoryIds
                                                .remove(cat.id)
                                            : selectedCategoryIds.add(cat.id);
                                      });
                                    },
                                  );
                                })
                                .toList(),
                          ),
                          if (categoryError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                categoryError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  if (coverImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        coverImage!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(
                      (coverImage != null || hadCoverInitially)
                          ? "Zamijeni naslovnicu"
                          : "Dodaj naslovnicu",
                    ),
                    onPressed: () async {
                      final result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null) {
                        setState(() {
                          coverImage = result.files.first.bytes;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  if (hadPdfInitially)
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Otvori postojeći PDF"),
                      onPressed: () {
                        final base64Pdf = initialData!['pdfFile'] as String;
                        openPdfFromBase64(context, base64Pdf);
                      },
                    ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      (pdfFile != null || hadPdfInitially)
                          ? "Zamijeni PDF"
                          : "Dodaj PDF",
                    ),
                    onPressed: () async {
                      final result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result != null) {
                        setState(() {
                          pdfFile = result.files.first.bytes;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade300,
                foregroundColor: Colors.black,
              ),
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  nameError = null;
                  priceError = null;
                  authorError = null;
                  categoryError = null;
                });

                bool hasError = false;

                if (nameController.text.trim().length < 3) {
                  nameError = "Naziv mora imati barem 3 karaktera.";
                  hasError = true;
                }

                final price =
                    double.tryParse(priceController.text.trim());
                if (price == null || price <= 0) {
                  priceError = "Unesite validnu cijenu.";
                  hasError = true;
                }

                if (selectedAuthorIds.isEmpty) {
                  authorError = "Odaberite najmanje jednog autora.";
                  hasError = true;
                }

                if (selectedCategoryIds.isEmpty) {
                  categoryError =
                      "Odaberite najmanje jednu kategoriju.";
                  hasError = true;
                }

                if (hasError) {
                  setState(() {});
                  return;
                }

                final bookData = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': price,
                  'coverImage': coverImage != null
                      ? base64Encode(coverImage!)
                      : null,
                  'pdfFile': pdfFile != null
                      ? base64Encode(pdfFile!)
                      : null,
                  'authorIds': selectedAuthorIds,
                  'categoryIds': selectedCategoryIds,
                };

                if (initialData != null) {
                  if (pdfFile == null) {
                    bookData.remove('pdfFile');
                  }
                  if (coverImage == null) {
                    bookData.remove('coverImage');
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Potvrda"),
                      content: const Text(
                        "Želite li sačuvati izmjene?",
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
                          child: const Text("Sačuvaj"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                }

                try {
                  if (initialData == null) {
                    await ApiService.createBook(bookData);
                  } else {
                    await ApiService.updateBook(
                      initialData['id'],
                      {
                        'id': initialData['id'],
                        ...bookData,
                      },
                    );
                  }

                  Navigator.pop(context);
                  refreshBooks();
                } catch (e) {
                  final message =
                      e.toString().replaceFirst("Exception: ", "");
                  errorDialog(context, message);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.black,
              ),
              child: Text(initialData == null ? "Dodaj" : "Sačuvaj"),
            ),
          ],
        ),
      );
    },
  );
}
