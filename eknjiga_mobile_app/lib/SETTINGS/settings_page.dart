import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './../HOME/home_page.dart';
import './../BOOKS/books_page.dart';
import './../SHOP/shop_page.dart';
import './../MESSAGES/messages_page.dart';
import './../LOGIN/login_page.dart';
import '../services/api_service.dart';
import '../utils/app_style.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4;

  final _formKey = GlobalKey<FormState>();
  final _imeCtrl = TextEditingController();
  final _prezimeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _lozinkaCtrl = TextEditingController();
  final _potvrdaCtrl = TextEditingController();

  String? _profileImageUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;

  final _picker = ImagePicker();
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (ApiService.userID == 0) {
        await ApiService.restoreSession();
      }

      if (ApiService.userID == 0) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
        return;
      }

      final user = await ApiService.fetchUserById();

      _imeCtrl.text = (user['firstName'] ?? '').toString();
      _prezimeCtrl.text = (user['lastName'] ?? '').toString();
      _emailCtrl.text = (user['email'] ?? '').toString();
      _profileImageUrl = (user['profileImage'] ?? '').toString();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri učitavanju profila: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pass = _lozinkaCtrl.text.trim();
    final confirm = _potvrdaCtrl.text.trim();

    if (pass.isNotEmpty && pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lozinka mora imati najmanje 6 znakova.'),
        ),
      );
      return;
    }

    if (pass.isNotEmpty && pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lozinke se ne poklapaju.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ApiService.updateUser(
        firstName: _imeCtrl.text.trim(),
        lastName: _prezimeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: pass.isEmpty ? null : pass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil je uspješno sačuvan.')),
      );

      _lozinkaCtrl.clear();
      _potvrdaCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri spremanju: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerija'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (xfile == null) return;

      setState(() {
        _pickedImageFile = File(xfile.path);
        _uploadingImage = true;
      });

      await ApiService.updateProfileImagePath(path: xfile.path);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilna slika je ažurirana.')),
      );

      await _init();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _imeCtrl.dispose();
    _prezimeCtrl.dispose();
    _emailCtrl.dispose();
    _lozinkaCtrl.dispose();
    _potvrdaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topColor = Color.fromARGB(255, 212, 217, 246);

    return Scaffold(
      backgroundColor: topColor,
      appBar: AppBar(
        backgroundColor: topColor,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('eKnjiga', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await ApiService.clearSession();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppStyle.pageDecoration,
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              const Text(
                                'MOJ PROFIL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _uploadingImage
                                    ? null
                                    : _showImageSourceSheet,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 52,
                                      backgroundColor: Colors.white,
                                      backgroundImage: _pickedImageFile != null
                                          ? FileImage(_pickedImageFile!)
                                          : (_profileImageUrl != null &&
                                                  _profileImageUrl!
                                                      .trim()
                                                      .isNotEmpty
                                              ? NetworkImage(ApiService.getImageUrl(_profileImageUrl))
                                              : null) as ImageProvider?,
                                      child: (_pickedImageFile == null &&
                                              (_profileImageUrl == null ||
                                                  _profileImageUrl!
                                                      .trim()
                                                      .isEmpty))
                                          ? const Icon(
                                              Icons.person,
                                              size: 45,
                                              color: Colors.blue,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.96),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: _uploadingImage
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt,
                                                color: Colors.black87,
                                                size: 18,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _imeCtrl,
                                      label: 'Ime',
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Unesite ime'
                                              : null,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _prezimeCtrl,
                                      label: 'Prezime',
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Unesite prezime'
                                              : null,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _emailCtrl,
                                      label: 'Email',
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      validator: (v) {
                                        final t = v?.trim() ?? '';
                                        if (t.isEmpty) {
                                          return 'Unesite email';
                                        }
                                        if (!t.contains('@')) {
                                          return 'Email nije ispravan';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _lozinkaCtrl,
                                      label: 'Lozinka (opcionalno)',
                                      obscure: true,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _potvrdaCtrl,
                                      label: 'Potvrdi lozinku',
                                      obscure: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF96A6DA),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SAČUVAJ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: (index) {
          if (index == _selectedIndex) return;

          setState(() => _selectedIndex = index);

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BookPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ShopPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MessagesPage()),
              );
              break;
            case 4:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 32), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.comment, size: 32), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: const TextStyle(color: Colors.black45),
      ),
    );
  }
}