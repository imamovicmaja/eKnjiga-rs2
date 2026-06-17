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
import '../models/city.dart';
import '../models/user_profile.dart';

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
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _staraLozinkaCtrl = TextEditingController();
  final _lozinkaCtrl = TextEditingController();
  final _potvrdaCtrl = TextEditingController();

  String? _profileImageUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _changePassword = false;

  final _picker = ImagePicker();
  File? _pickedImageFile;

  List<City> _cities = [];
  int? _selectedCityId;

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

      final results = await Future.wait([
        ApiService.fetchUserById(),
        ApiService.getCities(),
      ]);

      final user = results[0] as UserProfile;
      _cities = results[1] as List<City>;

      _imeCtrl.text = user.firstName;
      _prezimeCtrl.text = user.lastName;
      _emailCtrl.text = user.email;
      _usernameCtrl.text = user.username;
      _phoneCtrl.text = user.phoneNumber;
      _profileImageUrl = user.profileImage ?? '';

      _selectedCityId = user.city?.id;

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil nije moguće učitati. Pokušajte ponovo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      await ApiService.updateUser(
        firstName: _imeCtrl.text.trim(),
        lastName: _prezimeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        cityId: _selectedCityId,
        oldPassword: _changePassword ? _staraLozinkaCtrl.text.trim() : null,
        password: _changePassword ? _lozinkaCtrl.text.trim() : null,
        confirmPassword: _changePassword ? _potvrdaCtrl.text.trim() : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil je uspješno ažuriran.')),
      );

      setState(() => _changePassword = false);

      _staraLozinkaCtrl.clear();
      _lozinkaCtrl.clear();
      _potvrdaCtrl.clear();

      await _init();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Profil nije moguće ažurirati. Provjerite unesene podatke.'
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Promijeni profilnu sliku',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Kamera'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUpload(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Galerija'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUpload(ImageSource.gallery);
                    },
                  ),
                ],
              ),
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
        const SnackBar(content: Text('Profilna slika je uspješno ažurirana.')),
      );

      await _init();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilnu sliku nije moguće ažurirati.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  void dispose() {
    _imeCtrl.dispose();
    _prezimeCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _staraLozinkaCtrl.dispose();
    _lozinkaCtrl.dispose();
    _potvrdaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topColor = Color.fromARGB(255, 212, 217, 246);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              await ApiService.logout();
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
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          const Text(
                            'Moj profil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Uredite svoje podatke i sigurnosne postavke.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _profileCard(),

                          const SizedBox(height: 18),

                          _sectionCard(
                            title: 'Lični podaci',
                            icon: Icons.person_outline,
                            children: [
                              _buildLabeledField(
                                label: 'Ime',
                                icon: Icons.person_outline,
                                controller: _imeCtrl,
                                validator: _nameValidator('Ime'),
                              ),
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: 'Prezime',
                                icon: Icons.badge_outlined,
                                controller: _prezimeCtrl,
                                validator: _nameValidator('Prezime'),
                              ),
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: 'Korisničko ime',
                                icon: Icons.alternate_email,
                                controller: _usernameCtrl,
                                validator: _usernameValidator,
                              ),
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: 'Email adresa',
                                icon: Icons.email_outlined,
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: 'Broj telefona',
                                icon: Icons.phone_outlined,
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                validator: _phoneValidator,
                              ),
                              const SizedBox(height: 16),
                              _buildCityDropdown(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _sectionCard(
                            title: 'Sigurnost',
                            icon: Icons.lock_outline,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Promjena lozinke',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Uključite samo ako želite novu lozinku.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _changePassword,
                                      activeColor: const Color(0xFF7E90CF),
                                      onChanged: (value) {
                                        setState(() {
                                          _changePassword = value;

                                          if (!_changePassword) {
                                            _staraLozinkaCtrl.clear();
                                            _lozinkaCtrl.clear();
                                            _potvrdaCtrl.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              if (_changePassword) ...[
                                const SizedBox(height: 16),
                                _buildLabeledField(
                                  label: 'Stara lozinka',
                                  icon: Icons.lock_clock_outlined,
                                  controller: _staraLozinkaCtrl,
                                  obscure: true,
                                  validator: (v) {
                                    final t = v ?? '';
                                    if (t.isEmpty) {
                                      return 'Unesite staru lozinku.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildLabeledField(
                                  label: 'Nova lozinka',
                                  icon: Icons.lock_outline,
                                  controller: _lozinkaCtrl,
                                  obscure: true,
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 16),
                                _buildLabeledField(
                                  label: 'Potvrdi novu lozinku',
                                  icon: Icons.verified_user_outlined,
                                  controller: _potvrdaCtrl,
                                  obscure: true,
                                  validator: (v) {
                                    final t = v ?? '';

                                    if (t.isEmpty) {
                                      return 'Ponovite novu lozinku.';
                                    }

                                    if (t != _lozinkaCtrl.text) {
                                      return 'Lozinke se ne podudaraju.';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF96A6DA),
                                foregroundColor: Colors.black87,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child:
                                  _saving
                                      ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black87,
                                        ),
                                      )
                                      : const Text(
                                        'SAČUVAJ PROMJENE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.comment, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.42),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingImage ? null : _showImageSourceSheet,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _pickedImageFile != null
                          ? FileImage(_pickedImageFile!)
                          : (_profileImageUrl != null &&
                                      _profileImageUrl!.trim().isNotEmpty
                                  ? NetworkImage(
                                    ApiService.getImageUrl(_profileImageUrl),
                                  )
                                  : null)
                              as ImageProvider?,
                  child:
                      (_pickedImageFile == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.trim().isEmpty))
                          ? const Icon(
                            Icons.person,
                            size: 46,
                            color: Colors.black87,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.98),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child:
                        _uploadingImage
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
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
          const SizedBox(height: 14),
          Text(
            '${_imeCtrl.text.trim()} ${_prezimeCtrl.text.trim()}'.trim().isEmpty
                ? 'Korisnik'
                : '${_imeCtrl.text.trim()} ${_prezimeCtrl.text.trim()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text.trim(),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _uploadingImage ? null : _showImageSourceSheet,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Promijeni sliku'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              backgroundColor: Colors.white.withOpacity(0.55),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.36),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: Colors.black87),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(icon),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            'Grad',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        DropdownButtonFormField<int>(
          value: _selectedCityId,
          isExpanded: true,
          validator: (value) {
            if (value == null) {
              return 'Grad je obavezan.';
            }
            return null;
          },
          decoration: _inputDecoration(Icons.location_city_outlined),
          hint: const Text('Odaberite grad'),
          items:
              _cities
                  .map(
                    (city) => DropdownMenuItem<int>(
                      value: city.id,
                      child: Text(city.name),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() => _selectedCityId = value);
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.black54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.82),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF7E90CF), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  String? Function(String?) _nameValidator(String fieldName) {
    return (v) {
      final t = v?.trim() ?? '';

      if (t.isEmpty) {
        return '$fieldName je obavezno.';
      }

      if (t.length < 2) {
        return '$fieldName mora imati najmanje 2 slova.';
      }

      if (!RegExp(r"^[A-Za-zČĆŽŠĐčćžšđ\s'-]+$").hasMatch(t)) {
        return '$fieldName smije sadržavati samo slova.';
      }

      return null;
    };
  }

  String? _usernameValidator(String? v) {
    final t = v?.trim() ?? '';

    if (t.isEmpty) {
      return 'Korisničko ime je obavezno.';
    }

    if (t.length < 3) {
      return 'Korisničko ime mora imati najmanje 3 znaka.';
    }

    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(t)) {
      return 'Korisničko ime smije sadržavati slova, brojeve, tačku, crticu i donju crtu.';
    }

    return null;
  }

  String? _emailValidator(String? v) {
    final t = v?.trim() ?? '';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (t.isEmpty) {
      return 'Email je obavezan.';
    }

    if (!regex.hasMatch(t)) {
      return 'Unesite validan email.';
    }

    return null;
  }

  String? _phoneValidator(String? v) {
    final t = v?.trim() ?? '';

    if (t.isEmpty) {
      return 'Broj telefona je obavezan.';
    }

    if (!RegExp(r'^\+?[0-9\s\/-]{6,20}$').hasMatch(t)) {
      return 'Unesite validan broj telefona.';
    }

    return null;
  }

  String? _passwordValidator(String? v) {
    final t = v ?? '';

    if (t.isEmpty) {
      return 'Unesite novu lozinku.';
    }

    if (t.length < 6) {
      return 'Lozinka mora imati najmanje 6 znakova.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(t) || !RegExp(r'[0-9]').hasMatch(t)) {
      return 'Lozinka mora sadržavati barem jedno slovo i jedan broj.';
    }

    return null;
  }
}
