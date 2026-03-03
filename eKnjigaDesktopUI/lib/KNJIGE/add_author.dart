import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../dialog/error_dialog.dart';
import '../models/book.dart';

String _extractDateForInput(dynamic value) {
  if (value == null) return '';

  if (value is DateTime) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  final s = value.toString();
  if (s.isEmpty) return '';

  if (s.contains('T')) {
    return s.split('T').first;
  }
  if (s.contains(' ')) {
    return s.split(' ').first;
  }

  return s;
}

String _formatDateForDisplay(dynamic value) {
  final raw = _extractDateForInput(value);
  if (raw.isEmpty) return '';
  final parts = raw.split('-');
  if (parts.length != 3) return raw;

  final year = parts[0];
  final month = parts[1].padLeft(2, '0');
  final day = parts[2].padLeft(2, '0');
  return '$day.$month.$year';
}

String formatAuthorDate(dynamic value) => _formatDateForDisplay(value);

DateTime? _tryParseAnyDateToDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  final s = value.toString().trim();
  if (s.isEmpty) return null;

  if (s.contains('.')) {
    final parts = s.split('.');
    if (parts.length >= 3) {
      final dd = int.tryParse(parts[0]);
      final mm = int.tryParse(parts[1]);
      final yyyy = int.tryParse(parts[2]);
      if (dd != null && mm != null && yyyy != null) {
        return DateTime(yyyy, mm, dd);
      }
    }
  }

  final raw = _extractDateForInput(s);
  final parsed = DateTime.tryParse(raw);
  return parsed;
}

String? _normalizeDateForApi(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;

  if (t.contains('.')) {
    final parts = t.split('.');
    if (parts.length >= 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
  }

  return t;
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

void showAuthorDetailsDialog(
  BuildContext context,
  Map<String, dynamic> author,
) {
  final firstName = author['firstName']?.toString() ?? '';
  final lastName = author['lastName']?.toString() ?? '';
  final fullName =
      [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();

  final description = author['description']?.toString();
  final booksRaw = author['books'];
  final List<dynamic> books =
      (booksRaw is List) ? booksRaw : const <dynamic>[];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(
            Icons.person_outline,
            color: Color.fromARGB(255, 181, 156, 74),
            size: 30,
          ),
          const SizedBox(width: 8),
          Text(
            fullName.isEmpty ? 'Autor' : fullName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Ime', firstName.isEmpty ? '—' : firstName),
              _infoRow('Prezime', lastName.isEmpty ? '—' : lastName),
              _infoRow(
                'Datum rođenja',
                _formatDateForDisplay(author['birthDate']),
              ),
              _infoRow(
                'Datum smrti',
                _formatDateForDisplay(author['deathDate']),
              ),
              const SizedBox(height: 12),
              const Text(
                'Opis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(description?.isNotEmpty == true ? description! : '—'),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Knjige autora:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (books.isEmpty)
                const Text('Autor trenutno nema dodanih knjiga.')
              else
                ...books.map((b) {
                  String bookName = 'Nepoznata knjiga';
                  double? price;
                  double? rating;

                  if (b is Book) {
                    bookName = b.name;
                    price = b.price;
                    rating = b.rating;
                  } else if (b is Map<String, dynamic>) {
                    bookName = b['name']?.toString() ?? 'Nepoznata knjiga';
                    final p = b['price'];
                    final r = b['rating'];
                    if (p is num) price = p.toDouble();
                    if (r is num) rating = r.toDouble();
                  } else if (b is Map) {
                    final map = b.cast<String, dynamic>();
                    bookName = map['name']?.toString() ?? 'Nepoznata knjiga';
                    final p = map['price'];
                    final r = map['rating'];
                    if (p is num) price = p.toDouble();
                    if (r is num) rating = r.toDouble();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📖 $bookName',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (price != null)
                          Text('Cijena: ${price.toStringAsFixed(2)} KM'),
                        if (rating != null)
                          Text('Ocjena: ${rating.toStringAsFixed(1)}'),
                        const Divider(height: 12),
                      ],
                    ),
                  );
                }),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Zatvori'),
        ),
      ],
    ),
  );
}

void addAuthor(
  BuildContext context,
  VoidCallback refreshAuthors, {
  Map<String, dynamic>? initialData,
}) {
  final firstNameController = TextEditingController(
    text: initialData?['firstName']?.toString() ?? '',
  );
  final lastNameController = TextEditingController(
    text: initialData?['lastName']?.toString() ?? '',
  );

  final birthDateController = TextEditingController(
    text: _formatDateForDisplay(initialData?['birthDate']),
  );
  final deathDateController = TextEditingController(
    text: _formatDateForDisplay(initialData?['deathDate']),
  );

  final descriptionController = TextEditingController(
    text: initialData?['description']?.toString() ?? '',
  );

  String? firstNameError;
  String? lastNameError;
  String? birthDateError;
  String? deathDateError;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color.fromARGB(255, 181, 156, 74),
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                initialData == null ? 'Dodaj autora' : 'Uredi autora',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Ime',
                      errorText: firstNameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Prezime',
                      errorText: lastNameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: birthDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Datum rođenja (odaberi iz kalendara)',
                      errorText: birthDateError,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final now = DateTime.now();

                          final initial =
                              _tryParseAnyDateToDateTime(initialData?['birthDate']) ??
                                  _tryParseAnyDateToDateTime(
                                      birthDateController.text) ??
                                  now;

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1700),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            birthDateController.text =
                                _formatDateForDisplay(picked);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deathDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Datum smrti (opcijski)',
                      errorText: deathDateError,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final now = DateTime.now();

                          final initial =
                              _tryParseAnyDateToDateTime(initialData?['deathDate']) ??
                                  _tryParseAnyDateToDateTime(
                                      deathDateController.text) ??
                                  now;

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1700),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            deathDateController.text =
                                _formatDateForDisplay(picked);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Opis (opcijski)',
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  firstNameError = null;
                  lastNameError = null;
                  birthDateError = null;
                  deathDateError = null;
                });

                bool hasError = false;

                if (firstNameController.text.trim().length < 2) {
                  firstNameError = 'Ime mora imati barem 2 karaktera.';
                  hasError = true;
                }

                if (lastNameController.text.trim().length < 2) {
                  lastNameError = 'Prezime mora imati barem 2 karaktera.';
                  hasError = true;
                }

                final birthApi =
                    _normalizeDateForApi(birthDateController.text);
                final deathApi =
                    _normalizeDateForApi(deathDateController.text);

                if (hasError) {
                  setState(() {});
                  return;
                }

                final authorData = <String, dynamic>{
                  'firstName': firstNameController.text.trim(),
                  'lastName': lastNameController.text.trim(),
                  'birthDate': birthApi,
                  'deathDate': deathApi,
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'bookIds': <int>[],
                };

                if (initialData != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Potvrda izmjena'),
                      content: const Text(
                        'Jeste li sigurni da želite sačuvati promjene?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Otkaži'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sačuvaj'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }

                try {
                  if (initialData == null) {
                    await ApiService.createAuthor(authorData);
                  } else {
                    await ApiService.updateAuthor(initialData['id'], {
                      'id': initialData['id'],
                      ...authorData,
                    });
                  }

                  Navigator.pop(context);
                  refreshAuthors();
                } catch (e) {
                  final message =
                      e.toString().replaceFirst('Exception: ', '');
                  errorDialog(context, message);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.black,
              ),
              child: Text(initialData == null ? 'Dodaj' : 'Sačuvaj'),
            ),
          ],
        ),
      );
    },
  );
}
