import 'package:flutter/material.dart';

import '../KORISNICI/user_page.dart';
import '../NARUDZBE/order_page.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String errorText = "";
  bool isLoading = false;

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Unesite korisničko ime.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Unesite šifru.";
    }
    return null;
  }

  Future<void> handleLogin() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    setState(() {
      isLoading = true;
      errorText = "";
    });

    try {
      await ApiService.login(username, password);

      if (!mounted) return;

      if (ApiService.isEmployee) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 212, 217, 246),
              Color.fromARGB(255, 141, 158, 219),
              Color.fromARGB(255, 181, 156, 74),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "eKnjiga",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: usernameController,
                    validator: _validateUsername,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: _inputDecoration("Korisničko ime"),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: _inputDecoration("Šifra"),
                    onFieldSubmitted: (_) => handleLogin(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 181, 156, 74),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Prijavi se"),
                    ),
                  ),
                  if (errorText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}