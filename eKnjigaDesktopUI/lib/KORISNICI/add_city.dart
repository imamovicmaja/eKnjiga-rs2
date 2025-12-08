import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/country.dart';

import '../dialog/error_dialog.dart';

void addCity(
  BuildContext context,
  VoidCallback refreshCities, {
  Map<String, dynamic>? initialData,
}) {
  final nameController = TextEditingController(text: initialData?['name'] ?? '');
  final zipController = TextEditingController(
    text: initialData?['zipCode']?.toString() ?? '',
  );

  String? nameError;
  String? zipError;
  String? countryError;

  int selectedCountryId = (initialData?['country'] as Country?)?.id ?? 0;
  List<Country> availableCountries = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.location_city, color: Color.fromARGB(255, 181, 156, 74), size: 30),
              SizedBox(width: 8),
              Text("Grad", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    labelText: "Naziv grada",
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: zipController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Poštanski broj",
                    errorText: zipError,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Country>>(
                  future: ApiService.fetchCountries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text("Greška: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("Nema dostupnih država.");
                    }

                    availableCountries = snapshot.data!;
                    return DropdownButtonFormField<int>(
                      value: selectedCountryId == 0 ? null : selectedCountryId,
                      decoration: InputDecoration(
                        labelText: "Država",
                        errorText: countryError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: availableCountries.map((country) {
                        return DropdownMenuItem<int>(
                          value: country.id,
                          child: Text(country.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountryId = value!;
                        });
                      },
                    );
                  },
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
                  zipError = null;
                  countryError = null;
                });

                bool hasError = false;

                if (nameController.text.length < 2) {
                  nameError = "Naziv mora imati barem 2 karaktera.";
                  hasError = true;
                }

                final zip = int.tryParse(zipController.text);
                if (zip == null || zip < 10000 || zip > 99999) {
                  zipError = "Unesite validan poštanski broj (5 cifara).";
                  hasError = true;
                }

                if (selectedCountryId == 0) {
                  countryError = "Odaberite državu.";
                  hasError = true;
                }

                setState(() {});

                if (hasError) return;

                final cityData = {
                  'name': nameController.text.trim(),
                  'zipCode': zip,
                  'countryId': selectedCountryId,
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
                    await ApiService.createCity(cityData);
                  } else {
                    await ApiService.updateCity(initialData['id'], {
                      'id': initialData['id'],
                      ...cityData,
                    });
                  }

                  Navigator.pop(context);
                  refreshCities();
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
