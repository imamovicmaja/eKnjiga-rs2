import 'package:flutter/material.dart';
import '../services/api_service.dart';

import '../dialog/error_dialog.dart';

void addCategory(
  BuildContext context,
  VoidCallback refreshCategories, {
  Map<String, dynamic>? initialData,
}) {
  final nameController = TextEditingController(text: initialData?['name'] ?? '');
  String? nameError;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.category, color: Color.fromARGB(255, 181, 156, 74), size: 30),
              SizedBox(width: 8),
              Text("Kategorija", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Naziv kategorije",
                errorText: nameError,
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
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => nameError = null);

                if (nameController.text.trim().length < 2) {
                  setState(() => nameError = "Naziv mora imati barem 2 karaktera.");
                  return;
                }

                final categoryData = {
                  'name': nameController.text.trim(),
                  'bookIds': <int>[], // možeš kasnije dodati knjige
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
                    await ApiService.createCategory(categoryData);
                  } else {
                    await ApiService.updateCategory(initialData['id'], {
                      'id': initialData['id'],
                      ...categoryData,
                    });
                  }

                  Navigator.pop(context);
                  refreshCategories();
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
