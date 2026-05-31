import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  String? errorText;
  bool isLoading = false;

  List<dynamic> cities = [];
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
        errorText = "Gradovi se nisu mogli učitati.";
      });
    }
  }

  String _getCityName(dynamic city) {
    if (city is Map<String, dynamic>) {
      return (city['name'] ??
              city['cityName'] ??
              city['naziv'] ??
              city['grad'] ??
              '')
          .toString();
    }
    return '';
  }

  int? _getCityId(dynamic city) {
    if (city is Map<String, dynamic>) {
      final value = city['id'] ?? city['cityId'];
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    return null;
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
    }
  }

  void _showCityHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label je obavezno polje.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email je obavezno polje.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Unesite ispravan email.';
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

    final phoneRegex = RegExp(r'^[0-9+\-\s]{6,20}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Unesite ispravan broj telefona.';
    }

    return null;
  }

  Future<void> handleRegister() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (selectedCityId == null) {
      setState(() {
        errorText = "Odaberi grad.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      await ApiService.register({
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "username": usernameController.text.trim(),
        "password": passwordController.text,
        "phoneNumber": phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        "birthDate": selectedBirthDate?.toIso8601String(),
        "gender": selectedGender,
        "cityId": selectedCityId,
        "roleId": 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registracija uspješna. Prijavi se."),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = "Registracija nije uspjela. Provjeri podatke.";
      });
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
                        validator: (value) =>
                            _validateRequired(value, "Ime"),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        "Prezime",
                        lastNameController,
                        false,
                        validator: (value) =>
                            _validateRequired(value, "Prezime"),
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
                        validator: (value) =>
                            _validateRequired(value, "Korisničko ime"),
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
                          ),
                          child: Text(
                            selectedBirthDate == null
                                ? "Odaberi datum rođenja"
                                : "${selectedBirthDate!.day}.${selectedBirthDate!.month}.${selectedBirthDate!.year}",
                            style: TextStyle(
                              color: selectedBirthDate == null
                                  ? Colors.grey[700]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: InputDecoration(
                          labelText: "Spol",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text("Učitavanje gradova..."),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedCityId,
                          decoration: InputDecoration(
                            labelText: "Grad *",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items: cities
                              .map((city) {
                                final cityId = _getCityId(city);
                                final cityName = _getCityName(city);

                                if (cityId == null || cityName.isEmpty) {
                                  return null;
                                }

                                return DropdownMenuItem<int>(
                                  value: cityId,
                                  child: Text(cityName),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCityId = value;
                              errorText = null;
                            });
                          },
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

                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: isLoading ? null : handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 181, 156, 74),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}