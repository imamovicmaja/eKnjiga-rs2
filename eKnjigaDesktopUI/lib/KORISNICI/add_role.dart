import 'package:flutter/material.dart';
import '../services/api_service.dart';

import '../dialog/error_dialog.dart';

void addRole(
  BuildContext context,
  VoidCallback refreshRoles, {
  Map<String, dynamic>? initialData,
}) {
  final nameController = TextEditingController(text: initialData?['name'] ?? '');
  final descController = TextEditingController(text: initialData?['description'] ?? '');

  String? nameError;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.badge, color: Color.fromARGB(255, 181, 156, 74), size: 30),
              SizedBox(width: 8),
              Text("Uloga", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    labelText: "Naziv uloge",
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Opis uloge"),
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
                setState(() => nameError = null);
                final name = nameController.text.trim();
                final desc = descController.text.trim();

                if (name.length < 3) {
                  setState(() => nameError = "Naziv mora imati barem 3 karaktera.");
                  return;
                }

                final roleData = {
                  'name': name,
                  'description': desc,
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
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Otkaži"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Sačuvaj"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                }

                try {
                  if (initialData == null) {
                    await ApiService.createRole(roleData);
                  } else {
                    await ApiService.updateRole(initialData['id'], {
                      'id': initialData['id'],
                      ...roleData,
                    });
                  }

                  Navigator.pop(context);
                  refreshRoles();
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
