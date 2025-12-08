import 'package:flutter/material.dart';
import '../services/api_service.dart';

import '../dialog/error_dialog.dart';

void addCountry(
  BuildContext context,
  VoidCallback refreshCountries, {
  Map<String, dynamic>? initialData,
}) {
  final nameController = TextEditingController(text: initialData?['name'] ?? '');
  final codeController = TextEditingController(text: initialData?['code'] ?? '');

  String? nameError;
  String? codeError;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.public, color: Color.fromARGB(255, 181, 156, 74), size: 30),
              SizedBox(width: 8),
              Text("Država", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Naziv države",
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: "Kod države (npr. BA, HR)",
                    errorText: codeError,
                  ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  nameError = null;
                  codeError = null;
                });

                bool hasError = false;

                if (nameController.text.length < 2) {
                  nameError = "Naziv mora imati barem 2 karaktera.";
                  hasError = true;
                }

                if (codeController.text.length != 2) {
                  codeError = "Kod mora imati tačno 2 slova.";
                  hasError = true;
                }

                setState(() {});

                if (hasError) return;

                final countryData = {
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim().toUpperCase(),
                };

                if (initialData != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Potvrda izmjena"),
                      content: const Text("Jeste li sigurni da želite sačuvati promjene?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Otkaži"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Sačuvaj"),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }

                try {
                  if (initialData == null) {
                    await ApiService.createCountry(countryData);
                  } else {
                    await ApiService.updateCountry(initialData['id'], {
                      'id': initialData['id'],
                      ...countryData,
                    });
                  }

                  Navigator.pop(context);
                  refreshCountries();
                } catch (e) {
                  final message = e.toString().replaceFirst("Exception: ", "");
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
