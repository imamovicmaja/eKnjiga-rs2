import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../models/city.dart';
import '../models/role.dart';

import '../services/api_service.dart';

import '../dialog/error_dialog.dart';

void addUser(
  BuildContext context, 
  VoidCallback refreshUsers, {
  Map<String, dynamic>? initialData,
}) {
  final firstNameController = TextEditingController(
    text: initialData?['firstName'] ?? '',
  );
  final lastNameController = TextEditingController(
    text: initialData?['lastName'] ?? '',
  );
  final emailController = TextEditingController(
    text: initialData?['email'] ?? '',
  );
  final usernameController = TextEditingController(
    text: initialData?['username'] ?? '',
  );
  final phoneController = TextEditingController(
    text: initialData?['phoneNumber'] ?? '',
  );
  final birthDateController = TextEditingController(
    text: initialData?['birthDate']?.split('T')[0] ?? '',
  );
  final passwordController = TextEditingController();

  String? firstNameError;
  String? lastNameError;
  String? usernameError;
  String? roleError;
  String? cityError;
  String? passwordError;
  String? birthDateError;

  String gender = initialData?['gender'] ?? "Muško";
  int selectedRoleId = initialData?['role']?['id'] ?? 0;
  int selectedCityId = initialData?['city']?['id'] ?? 0;

  String? emailError;
  String? phoneError;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  List<City> availableCities = [];
  List<Role> availableRoles = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder:
            (context, setState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.person,
                    color: Color.fromARGB(255, 181, 156, 74),
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Dodaj novog korisnika",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                          labelText: "Ime",
                          errorText: firstNameError,
                        ),
                      ),

                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: "Prezime",
                          errorText: lastNameError,
                        ),
                      ),

                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: "Korisničko ime",
                          errorText: usernameError,
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          errorText: emailError,
                        ),
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Šifra",
                          errorText: passwordError,
                        ),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: "Telefon (+387...)",
                          errorText: phoneError,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            birthDateController.text =
                                date.toIso8601String().split('T')[0];
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: birthDateController,
                            decoration: InputDecoration(
                              labelText: "Datum rođenja",
                              errorText: birthDateError,
                            ),
                            readOnly: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      DropdownButtonFormField2<String>(
                        value: gender,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Spol",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
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
                          setState(() {
                            gender = value!;
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

                      /*FutureBuilder<List<Role>>(
                        future: ApiService.fetchRoles(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();

                          availableRoles = snapshot.data!;

                          return DropdownButtonFormField2<int>(
                            value: selectedRoleId == 0 ? null : selectedRoleId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Uloga",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items:
                                availableRoles.map((role) {
                                  return DropdownMenuItem<int>(
                                    value: role.id,
                                    child: Text(
                                      role.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoleId = value!;
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
                              height: 35,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          );
                        },
                      ),*/
                      FutureBuilder<List<Role>>(
                        future: ApiService.fetchRoles(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Text("Greška: ${snapshot.error}");
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text("Nema uloge");
                          }

                          availableRoles = snapshot.data!;

                          return DropdownButtonFormField2<int>(
                            value: selectedRoleId == 0 ? null : selectedRoleId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Uloga",
                              errorText: roleError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items:
                                availableRoles.map((role) {
                                  return DropdownMenuItem<int>(
                                    value: role.id,
                                    child: Text(
                                      role.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRoleId = value!;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      FutureBuilder<List<City>>(
                        future: ApiService.fetchCities(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Text("Greška: ${snapshot.error}");
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text("Nema gradova");
                          }

                          availableCities = snapshot.data!;

                          return DropdownButtonFormField2<int>(
                            value: selectedCityId == 0 ? null : selectedCityId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Grad",
                              errorText: cityError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items:
                                availableCities.map((city) {
                                  return DropdownMenuItem<int>(
                                    value: city.id,
                                    child: Text(
                                      city.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCityId = value!;
                              });
                            },
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
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),

                  child: const Text("Otkaži"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      emailError = null;
                      phoneError = null;
                      firstNameError = null;
                      lastNameError = null;
                      usernameError = null;
                      roleError = null;
                      cityError = null;
                      passwordError = null;
                      birthDateError = null;
                    });

                    bool hasError = false;
                    if (firstNameController.text.length < 3) {
                      setState(() {
                        firstNameError = "Ime mora imati barem 3 karaktera.";
                      });
                      hasError = true;
                    }

                    if (lastNameController.text.length < 3) {
                      setState(() {
                        lastNameError = "Prezime mora imati barem 3 karaktera.";
                      });
                      hasError = true;
                    }

                    if (usernameController.text.length < 6) {
                      setState(() {
                        usernameError =
                            "Korisničko ime mora imati barem 6 karaktera.";
                      });
                      hasError = true;
                    }

                    if (!emailRegex.hasMatch(emailController.text)) {
                      setState(() {
                        emailError = "Unesite ispravan email.";
                      });
                      hasError = true;
                    }

                    if (!phoneRegex.hasMatch(phoneController.text)) {
                      setState(() {
                        phoneError = "Unesite ispravan broj telefona.";
                      });
                      hasError = true;
                    }

                    if (selectedRoleId == 0) {
                      setState(() {
                        roleError = "Odaberite ulogu.";
                      });
                      hasError = true;
                    }

                    if (selectedCityId == 0) {
                      setState(() {
                        cityError = "Odaberite grad.";
                      });
                      hasError = true;
                    }

                    if (initialData == null &&
                        passwordController.text.length < 8) {
                      setState(() {
                        passwordError = "Šifra mora imati barem 8 karaktera.";
                      });
                      hasError = true;
                    } else if (passwordController.text.isNotEmpty &&
                        passwordController.text.length < 8) {
                      setState(() {
                        passwordError = "Šifra mora imati barem 8 karaktera.";
                      });
                      hasError = true;
                    }

                    if (birthDateController.text.isEmpty) {
                      setState(() {
                        birthDateError = "Odaberite datum rođenja.";
                      });
                      hasError = true;
                    }

                    if (hasError) return;

                    final newUser = {
                      "firstName": firstNameController.text,
                      "lastName": lastNameController.text,
                      "email": emailController.text,
                      "username": usernameController.text,
                      "phoneNumber": phoneController.text,
                      "birthDate": birthDateController.text,
                      "gender": gender,
                      "roleId": selectedRoleId,
                      "cityId": selectedCityId,
                    };
                    if (passwordController.text.isNotEmpty) {
                      newUser["password"] = passwordController.text;
                    }

                    /*try {
                      if (initialData == null) {
                        await ApiService.createUser(newUser);
                      } else {
                        final id = initialData['id'];
                        await ApiService.updateUser(id, newUser);
                      }
                      Navigator.pop(context);
                      refreshUsers();
                    } catch (e) {
                      print("Greška: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Greška pri ${initialData == null ? 'dodavanju' : 'ažuriranju'} korisnika.",
                          ),
                        ),
                      );
                    }*/
                    if (initialData != null) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("Potvrda izmjena"),
                              content: const Text(
                                "Jeste li sigurni da želite sačuvati promjene?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red.shade300,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(
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
                                    padding: EdgeInsets.symmetric(
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
                      final message = e.toString().replaceFirst("Exception: ", "");
                      errorDialog(context, message); 
                    }
                    /*print({
                      "firstName": firstNameController.text,
                      "lastName": lastNameController.text,
                      "email": emailController.text,
                      "username": usernameController.text,
                      "phoneNumber": phoneController.text,
                      "birthDate": birthDateController.text,
                      "gender": gender,
                      "password": passwordController.text,
                      "roleId": selectedRoleId,
                      "cityId": selectedCityId,
                    });*/
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(initialData == null ? "Dodaj" : "Edituj"),
                ),
              ],
            ),
      );
    },
  );
}
