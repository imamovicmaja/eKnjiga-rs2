import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../models/city.dart';
import '../models/role.dart';
import '../services/api_service.dart';
import '../dialog/error_dialog.dart';

String _formatDateForDisplayFromIso(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final raw = iso.split('T')[0];
  final parts = raw.split('-');
  if (parts.length != 3) return raw;
  return '${parts[2].padLeft(2, '0')}.${parts[1].padLeft(2, '0')}.${parts[0]}';
}

DateTime _parseInitialBirthDate(String? isoOrNull) {
  if (isoOrNull == null || isoOrNull.isEmpty) return DateTime(2000);
  final raw = isoOrNull.split('T')[0];
  final parsed = DateTime.tryParse(raw);
  return parsed ?? DateTime(2000);
}

String _normalizeBirthDateForApi(String input) {
  final t = input.trim();
  if (t.isEmpty) return t;

  if (t.contains('.')) {
    final parts = t.split('.');
    if (parts.length == 3) {
      final dd = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      final yyyy = parts[2];
      return '$yyyy-$mm-$dd';
    }
  }

  return t;
}

void addUser(
  BuildContext context,
  VoidCallback refreshUsers, {
  Map<String, dynamic>? initialData,
}) {
  final firstNameController = TextEditingController(
    text: initialData?['firstName']?.toString() ?? '',
  );
  final lastNameController = TextEditingController(
    text: initialData?['lastName']?.toString() ?? '',
  );
  final emailController = TextEditingController(
    text: initialData?['email']?.toString() ?? '',
  );
  final usernameController = TextEditingController(
    text: initialData?['username']?.toString() ?? '',
  );
  final phoneController = TextEditingController(
    text: initialData?['phoneNumber']?.toString() ?? '',
  );
  final birthDateController = TextEditingController(
    text: _formatDateForDisplayFromIso(initialData?['birthDate']?.toString()),
  );
  final passwordController = TextEditingController();

  String? firstNameError;
  String? lastNameError;
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? phoneError;
  String? birthDateError;
  String? roleError;
  String? cityError;

  String gender = (initialData?['gender']?.toString().isNotEmpty ?? false)
      ? initialData!['gender'].toString()
      : "Muško";

  int selectedRoleId = initialData?['role']?['id'] ?? 0;
  int selectedCityId = initialData?['city']?['id'] ?? 0;

  List<City> availableCities = [];
  List<Role> availableRoles = [];

  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final phoneRegex = RegExp(r'^[0-9+\-\s]{6,20}$');

  InputDecoration _inputDecoration(
    String label, {
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    );
  }

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
                Icons.person,
                color: Color.fromARGB(255, 181, 156, 74),
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                initialData == null
                    ? "Dodaj novog korisnika"
                    : "Uredi korisnika",
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
                    decoration: _inputDecoration(
                      "Ime",
                      errorText: firstNameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameController,
                    decoration: _inputDecoration(
                      "Prezime",
                      errorText: lastNameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: _inputDecoration(
                      "Korisničko ime",
                      errorText: usernameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      "Email",
                      errorText: emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      initialData == null
                          ? "Šifra"
                          : "Nova šifra (opcionalno)",
                      errorText: passwordError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      "Telefon (+387...)",
                      errorText: phoneError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _parseInitialBirthDate(
                          initialData?['birthDate']?.toString(),
                        ),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );

                      if (date != null) {
                        setState(() {
                          birthDateController.text =
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                          birthDateError = null;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: birthDateController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          "Datum rođenja",
                          errorText: birthDateError,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField2<String>(
                    value: gender,
                    isExpanded: true,
                    decoration: _inputDecoration("Spol"),
                    items: const [
                      DropdownMenuItem(
                        value: "Muško",
                        child: Text(
                          "Muško",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Žensko",
                        child: Text(
                          "Žensko",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        gender = value;
                      });
                    },
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 160,
                      width: 360,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 36,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Role>>(
                    future: ApiService.fetchRoles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          "Greška pri učitavanju uloga: ${snapshot.error}",
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("Nema dostupnih uloga.");
                      }

                      availableRoles = snapshot.data!;

                      final validSelectedRole = availableRoles.any(
                        (r) => r.id == selectedRoleId,
                      );

                      return DropdownButtonFormField2<int>(
                        value: validSelectedRole && selectedRoleId != 0
                            ? selectedRoleId
                            : null,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          "Uloga",
                          errorText: roleError,
                        ),
                        items: availableRoles.map((role) {
                          return DropdownMenuItem<int>(
                            value: role.id,
                            child: Text(
                              role.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRoleId = value ?? 0;
                            roleError = null;
                          });
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: 360,
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<City>>(
                    future: ApiService.fetchCities(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          "Greška pri učitavanju gradova: ${snapshot.error}",
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("Nema dostupnih gradova.");
                      }

                      availableCities = snapshot.data!;

                      final validSelectedCity = availableCities.any(
                        (c) => c.id == selectedCityId,
                      );

                      return DropdownButtonFormField2<int>(
                        value: validSelectedCity && selectedCityId != 0
                            ? selectedCityId
                            : null,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          "Grad",
                          errorText: cityError,
                        ),
                        items: availableCities.map((city) {
                          return DropdownMenuItem<int>(
                            value: city.id,
                            child: Text(
                              city.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCityId = value ?? 0;
                            cityError = null;
                          });
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: 360,
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text("Otkaži"),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  firstNameError = null;
                  lastNameError = null;
                  usernameError = null;
                  emailError = null;
                  passwordError = null;
                  phoneError = null;
                  birthDateError = null;
                  roleError = null;
                  cityError = null;
                });

                bool hasError = false;

                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final username = usernameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text;
                final phone = phoneController.text.trim();
                final birthDate = birthDateController.text.trim();

                if (firstName.length < 2) {
                  firstNameError = "Ime mora imati barem 2 karaktera.";
                  hasError = true;
                }

                if (lastName.length < 2) {
                  lastNameError = "Prezime mora imati barem 2 karaktera.";
                  hasError = true;
                }

                if (username.length < 3) {
                  usernameError =
                      "Korisničko ime mora imati barem 3 karaktera.";
                  hasError = true;
                }

                if (email.isEmpty) {
                  emailError = "Email je obavezan.";
                  hasError = true;
                } else if (!emailRegex.hasMatch(email)) {
                  emailError = "Unesite ispravan email.";
                  hasError = true;
                }

                if (initialData == null) {
                  if (password.isEmpty) {
                    passwordError = "Šifra je obavezna.";
                    hasError = true;
                  } else if (password.length < 6) {
                    passwordError =
                        "Šifra mora imati najmanje 6 karaktera.";
                    hasError = true;
                  }
                } else {
                  if (password.isNotEmpty && password.length < 6) {
                    passwordError =
                        "Nova šifra mora imati najmanje 6 karaktera.";
                    hasError = true;
                  }
                }

                if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
                  phoneError =
                      "Dozvoljeni su brojevi, razmak, + i - (6 do 20 znakova).";
                  hasError = true;
                }

                if (birthDate.isEmpty) {
                  birthDateError = "Datum rođenja je obavezan.";
                  hasError = true;
                }

                if (selectedRoleId == 0) {
                  roleError = "Odaberite ulogu.";
                  hasError = true;
                }

                if (selectedCityId == 0) {
                  cityError = "Odaberite grad.";
                  hasError = true;
                }

                setState(() {});

                if (hasError) return;

                final newUser = <String, dynamic>{
                  "firstName": firstName,
                  "lastName": lastName,
                  "email": email,
                  "username": username,
                  "phoneNumber": phone,
                  "birthDate": _normalizeBirthDateForApi(birthDate),
                  "gender": gender,
                  "roleId": selectedRoleId,
                  "cityId": selectedCityId,
                };

                if (password.isNotEmpty) {
                  newUser["password"] = password;
                }

                if (initialData != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Potvrda izmjena"),
                      content: const Text(
                        "Jeste li sigurni da želite sačuvati promjene?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text("Otkaži"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text("Edituj"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;
                }

                try {
                  if (initialData == null) {
                    await ApiService.createUser(newUser);
                  } else {
                    final id = initialData['id'];
                    await ApiService.updateUser(id, newUser);
                  }

                  Navigator.pop(context);
                  refreshUsers();
                } catch (e) {
                  final message =
                      e.toString().replaceFirst("Exception: ", "");
                  errorDialog(context, message);
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(initialData == null ? "Dodaj" : "Edituj"),
            ),
          ],
        ),
      );
    },
  );
}