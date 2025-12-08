import 'package:flutter/material.dart';
import '../KORISNICI/user_page.dart';

import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String errorText = "";

  void handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    
    /* Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserPage()),
    ); */

    try {
      final fetched = await ApiService.login(username, password);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserPage()),
      );
    } catch (e) {
      setState(() {
        errorText = "Pogrešno korisničko ime ili šifra!";
      });
    }

    /* if (username == "admin" && password == "admin123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserPage()),
      );
    } else {
      setState(() {
        errorText = "Pogrešno korisničko ime ili šifra!";
      });
    } */
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "eKnjiga",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "Korisničko ime",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Šifra"),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 181, 156, 74),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Prijavi se"),
                ),
                const SizedBox(height: 12),
                Text(errorText, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
