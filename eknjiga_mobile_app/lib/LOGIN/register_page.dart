import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/city.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  DateTime? selectedBirthDate;
  String? selectedGender;
  bool isLoading = false;

  List<City> cities = [];
  int? selectedCityId;
  bool isCitiesLoading = true;

  @override
  void initState() {
    super.initState();
    loadCities();
  }

  Future<void> loadCities() async {
    try {
      final result = await ApiService.getCities();

      if (!mounted) return;

      setState(() {
        cities = result;
        isCitiesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCitiesLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gradovi se nisu mogli učitati.")),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
      });

      _formKey.currentState?.validate();
    }
  }

  void _showCityHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text("Grad nije na listi"),
            content: const Text(
              "Ako ne možeš pronaći svoj grad, trenutno odaberi najbliži dostupni grad ili kontaktiraj podršku/admina kako bi grad bio dodan u sistem.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("U redu"),
              ),
            ],
          ),
    );
  }

  String? _validateName(String? value, String label) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$label je obavezno polje.';
    }

    if (text.length < 2) {
      return '$label mora imati najmanje 2 karaktera.';
    }

    if (text.length > 50) {
      return '$label ne smije imati više od 50 karaktera.';
    }

    if (!RegExp(r"^[A-Za-zČĆŽŠĐčćžšđ\s'-]+$").hasMatch(text)) {
      return '$label smije sadržavati samo slova.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email je obavezno polje.';
    }

    if (email.length > 100) {
      return 'Email ne smije imati više od 100 karaktera.';
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Unesite email u formatu primjer@email.com.';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return 'Korisničko ime je obavezno polje.';
    }

    if (username.length < 3) {
      return 'Korisničko ime mora imati najmanje 3 karaktera.';
    }

    if (username.length > 30) {
      return 'Korisničko ime ne smije imati više od 30 karaktera.';
    }

    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(username)) {
      return 'Korisničko ime smije sadržavati slova, brojeve, tačku, crticu i donju crtu.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Šifra je obavezno polje.';
    }

    if (password.length < 6) {
      return 'Šifra mora imati najmanje 6 karaktera.';
    }

    if (password.length > 100) {
      return 'Šifra ne smije imati više od 100 karaktera.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Šifra mora sadržavati barem jedno veliko slovo.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Šifra mora sadržavati barem jedno malo slovo.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Šifra mora sadržavati barem jedan broj.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) {
      return 'Potvrda šifre je obavezno polje.';
    }

    if (confirmPassword != passwordController.text) {
      return 'Šifre se ne podudaraju.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return null;
    }

    if (phone.length < 6 || phone.length > 20) {
      return 'Broj telefona mora imati između 6 i 20 karaktera.';
    }

    if (!RegExp(r'^\+?[0-9\s/-]+$').hasMatch(phone)) {
      return 'Broj telefona smije sadržavati brojeve, razmake, /, - i opcionalno + na početku.';
    }

    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length < 6) {
      return 'Broj telefona mora sadržavati najmanje 6 cifara.';
    }

    return null;
  }

  String? _validateBirthDate(DateTime? value) {
    if (value == null) {
      return 'Datum rođenja je obavezno polje.';
    }

    final today = DateTime.now();
    final age =
        today.year -
        value.year -
        ((today.month < value.month ||
                (today.month == value.month && today.day < value.day))
            ? 1
            : 0);

    if (age < 13) {
      return 'Korisnik mora imati najmanje 13 godina.';
    }

    if (age > 120) {
      return 'Unesite ispravan datum rođenja.';
    }

    return null;
  }

  Future<void> handleRegister() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.register({
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "username": usernameController.text.trim(),
        "password": passwordController.text,
        "phoneNumber":
            phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
        "birthDate": selectedBirthDate?.toIso8601String(),
        "gender": selectedGender,
        "cityId": selectedCityId,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registracija uspješna. Prijavi se.")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registracija nije uspjela. Provjeri podatke."),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 212, 217, 246),
              Color.fromARGB(255, 141, 158, 219),
              Color.fromARGB(255, 181, 156, 74),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Registracija",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        "Ime",
                        firstNameController,
                        false,
                        validator: (value) => _validateName(value, "Ime"),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Prezime",
                        lastNameController,
                        false,
                        validator: (value) => _validateName(value, "Prezime"),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Email",
                        emailController,
                        false,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Korisničko ime",
                        usernameController,
                        false,
                        validator: _validateUsername,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Šifra",
                        passwordController,
                        true,
                        validator: _validatePassword,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Potvrdi šifru",
                        confirmPasswordController,
                        true,
                        validator: _validateConfirmPassword,
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        "Broj telefona",
                        phoneController,
                        false,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),

                      const SizedBox(height: 16),

                      FormField<DateTime>(
                        validator: (_) => _validateBirthDate(selectedBirthDate),
                        builder: (field) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _pickBirthDate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        field.hasError
                                            ? Border.all(color: Colors.red)
                                            : null,
                                  ),
                                  child: Text(
                                    selectedBirthDate == null
                                        ? "Odaberi datum rođenja"
                                        : "${selectedBirthDate!.day}.${selectedBirthDate!.month}.${selectedBirthDate!.year}",
                                    style: TextStyle(
                                      color:
                                          selectedBirthDate == null
                                              ? Colors.grey[700]
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              if (field.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    top: 6,
                                  ),
                                  child: Text(
                                    field.errorText!,
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

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Spol je obavezno polje.';
                          }
                          return null;
                        },
                        decoration: _dropdownDecoration("Spol"),
                        items: const [
                          DropdownMenuItem(
                            value: "Muško",
                            child: Text("Muško"),
                          ),
                          DropdownMenuItem(
                            value: "Žensko",
                            child: Text("Žensko"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 16),

                      if (isCitiesLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text("Učitavanje gradova..."),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedCityId,
                          validator: (value) {
                            if (value == null) {
                              return 'Grad je obavezno polje.';
                            }
                            return null;
                          },
                          decoration: _dropdownDecoration("Grad *"),
                          items:
                              cities
                                  .map(
                                    (city) => DropdownMenuItem<int>(
                                      value: city.id,
                                      child: Text(city.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCityId = value;
                            });
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showCityHelpDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text(
                            "Moj grad nije na listi",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: isLoading ? null : handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            181,
                            156,
                            74,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text("REGISTRUJ SE"),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Već imaš račun? Prijavi se",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black54, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool obscure, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
