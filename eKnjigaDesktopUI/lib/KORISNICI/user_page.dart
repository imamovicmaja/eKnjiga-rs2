import 'package:flutter/material.dart';
import 'dart:async';

import '../FORUM/forum_page.dart';
import '../KNJIGE/books_page.dart';
import '../NARUDZBE/order_page.dart';
import '../LOGIN/login_page.dart';

import './add_user.dart';
import './add_role.dart';
import './add_city.dart';
import './add_country.dart';

import '../services/api_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String selectedSidebar = "KORISNICI";

  int? _selectedRoleId;

  final TextEditingController _roleSearchCtrl = TextEditingController();
  String _roleSearchQuery = "";

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  final TextEditingController _cityNameCtrl = TextEditingController();
  final TextEditingController _cityZipCtrl = TextEditingController();

  final TextEditingController _countryNameCtrl = TextEditingController();
  final TextEditingController _countryCodeCtrl = TextEditingController();

  Timer? _debounce;
  static const _debounceMs = 450;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> countries = [];

  bool _loadingRoles = false;
  bool _loadingUsers = false;
  bool _loadingCities = false;
  bool _loadingCountries = false;

  @override
  void initState() {
    super.initState();
    loadUsersFromApi();
    loadRolesFromApi();
    loadCitiesFromApi();
    loadCountriesFromApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _roleSearchCtrl.dispose();

    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();

    _cityNameCtrl.dispose();
    _cityZipCtrl.dispose();

    _countryNameCtrl.dispose();
    _countryCodeCtrl.dispose();

    super.dispose();
  }

  Future<void> loadUsersFromApi({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    int? roleId, 
  }) async {
    try {
      if (mounted) setState(() => _loadingUsers = true);

      final fetched = await ApiService.fetchUsers(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        roleId: roleId,
      );

      setState(() {
        users = fetched;
      });
    } catch (e) {
      debugPrint("Greška pri učitavanju korisnika: $e");
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  void _onUserFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final username = _usernameCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      final allEmpty =
          [firstName, lastName, username, email].every((s) => s.isEmpty) &&
          _selectedRoleId == null;

      if (allEmpty) {
        loadUsersFromApi();
      } else {
        loadUsersFromApi(
          firstName: firstName.isEmpty ? null : firstName,
          lastName: lastName.isEmpty ? null : lastName,
          username: username.isEmpty ? null : username,
          email: email.isEmpty ? null : email,
          roleId: _selectedRoleId,
        );
      }
    });
  }

  Future<void> loadRolesFromApi({String? name}) async {
    try {
      if (mounted) setState(() => _loadingRoles = true);

      final fetched = await ApiService.fetchRoles(name: name);
      setState(() {
        roles =
            fetched
                .map(
                  (role) => {
                    'id': role.id,
                    'name': role.name,
                    'description': role.description,
                  },
                )
                .toList();
      });
    } catch (e) {
      debugPrint("Greška pri učitavanju uloga: $e");
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  void _onRoleSearchChanged(String v) {
    setState(() => _roleSearchQuery = v);
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final q = _roleSearchQuery.trim();
      if (q.isEmpty) {
        loadRolesFromApi();
      } else {
        loadRolesFromApi(name: q);
      }
    });
  }

  Future<void> loadCitiesFromApi({String? name, int? zipCode}) async {
    try {
      if (mounted) setState(() => _loadingCities = true);

      final fetched = await ApiService.fetchCities(
        name: name,
        zipCode: zipCode,
      );
      setState(() {
        cities =
            fetched
                .map(
                  (city) => {
                    'id': city.id,
                    'name': city.name,
                    'zipCode': city.zipCode,
                    'country': city.country,
                  },
                )
                .toList();
      });
    } catch (e) {
      debugPrint("Greška pri učitavanju gradova: $e");
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  void _onCityFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final name = _cityNameCtrl.text.trim();
      final zipStr = _cityZipCtrl.text.trim();

      int? zip;
      if (zipStr.isNotEmpty) {
        final onlyDigits = zipStr.replaceAll(RegExp(r'[^0-9]'), '');
        zip = int.tryParse(onlyDigits);
      }

      final allEmpty = name.isEmpty && (zip == null);
      if (allEmpty) {
        loadCitiesFromApi();
      } else {
        loadCitiesFromApi(name: name.isEmpty ? null : name, zipCode: zip);
      }
    });
  }

  Future<void> loadCountriesFromApi({String? name, String? code}) async {
    try {
      if (mounted) setState(() => _loadingCountries = true);

      final fetched = await ApiService.fetchCountries(name: name, code: code);
      setState(() {
        countries =
            fetched
                .map((c) => {'id': c.id, 'name': c.name, 'code': c.code})
                .toList();
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju država: $e");
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  void _onCountryFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final name = _countryNameCtrl.text.trim();
      final code = _countryCodeCtrl.text.trim();

      final allEmpty = name.isEmpty && code.isEmpty;
      if (allEmpty) {
        loadCountriesFromApi();
      } else {
        loadCountriesFromApi(
          name: name.isEmpty ? null : name,
          code: code.isEmpty ? null : code,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),

          Column(
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                color: Colors.white.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "eKnjiga",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(width: 50),
                        navTab("KORISNICI", context, isActive: true),
                        const SizedBox(width: 32),
                        navTab("KNJIGE", context),
                        const SizedBox(width: 32),
                        navTab("NARUDŽBE", context),
                        const SizedBox(width: 32),
                        navTab("FORUM", context),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          181,
                          156,
                          74,
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Odjavi se"),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 180,
                      color: Colors.white.withOpacity(0.8),
                      padding: const EdgeInsets.only(top: 32, left: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sidebarOption("KORISNICI", Icons.person),
                          const SizedBox(height: 24),
                          sidebarOption("ULOGE", Icons.badge),
                          const SizedBox(height: 24),
                          sidebarOption("GRADOVI", Icons.location_city),
                          const SizedBox(height: 24),
                          sidebarOption("DRŽAVE", Icons.public),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedSidebar == "ULOGE") ...[
                                  SizedBox(
                                    width: 300,
                                    child: TextField(
                                      controller: _roleSearchCtrl,
                                      onChanged: _onRoleSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: "Pretraži uloge po nazivu...",
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon:
                                            _loadingRoles
                                                ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                )
                                                : (_roleSearchQuery.isEmpty
                                                    ? null
                                                    : IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                      ),
                                                      onPressed: () {
                                                        _roleSearchCtrl.clear();
                                                        _onRoleSearchChanged(
                                                          "",
                                                        );
                                                      },
                                                    )),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.9,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (selectedSidebar == "KORISNICI") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _userFilterField(
                                          label: "Ime",
                                          controller: _firstNameCtrl,
                                          loading: _loadingUsers,
                                          onChanged:
                                              (_) => _onUserFieldChanged(),
                                        ),
                                        _userFilterField(
                                          label: "Prezime",
                                          controller: _lastNameCtrl,
                                          loading: _loadingUsers,
                                          onChanged:
                                              (_) => _onUserFieldChanged(),
                                        ),
                                        _userFilterField(
                                          label: "Username",
                                          controller: _usernameCtrl,
                                          loading: _loadingUsers,
                                          onChanged:
                                              (_) => _onUserFieldChanged(),
                                        ),
                                        _userFilterField(
                                          label: "Email",
                                          controller: _emailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          loading: _loadingUsers,
                                          onChanged:
                                              (_) => _onUserFieldChanged(),
                                        ),

                                        SizedBox(
                                          width: 220,
                                          child: DropdownButtonFormField<int?>(
                                            value: _selectedRoleId,
                                            decoration: InputDecoration(
                                              labelText: "Uloga",
                                              prefixIcon: const Icon(
                                                Icons.badge,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: null,
                                                child: Text("Sve uloge"),
                                              ),
                                              ...roles.map(
                                                (r) => DropdownMenuItem(
                                                  value: r['id'] as int,
                                                  child: Text(r['name']),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedRoleId = value;
                                              });
                                              _onUserFieldChanged();
                                            },
                                          ),
                                        ),

                                        TextButton.icon(
                                          onPressed: () {
                                            _firstNameCtrl.clear();
                                            _lastNameCtrl.clear();
                                            _usernameCtrl.clear();
                                            _emailCtrl.clear();
                                            _onUserFieldChanged();
                                          },
                                          icon: const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (selectedSidebar == "GRADOVI") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _cityFilterField(
                                          label: "Naziv",
                                          controller: _cityNameCtrl,
                                          loading: _loadingCities,
                                          onChanged:
                                              (_) => _onCityFieldChanged(),
                                        ),
                                        _cityFilterField(
                                          label: "Poštanski broj",
                                          controller: _cityZipCtrl,
                                          keyboardType: TextInputType.number,
                                          loading: _loadingCities,
                                          onChanged:
                                              (_) => _onCityFieldChanged(),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            _cityNameCtrl.clear();
                                            _cityZipCtrl.clear();
                                            _onCityFieldChanged();
                                          },
                                          icon: const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (selectedSidebar == "DRŽAVE") ...[
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _cityFilterField(
                                          label: "Naziv",
                                          controller: _countryNameCtrl,
                                          loading: _loadingCountries,
                                          onChanged:
                                              (_) => _onCountryFieldChanged(),
                                        ),
                                        _cityFilterField(
                                          label: "Kod",
                                          controller: _countryCodeCtrl,
                                          loading: _loadingCountries,
                                          onChanged:
                                              (_) => _onCountryFieldChanged(),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            _countryNameCtrl.clear();
                                            _countryCodeCtrl.clear();
                                            _onCountryFieldChanged();
                                          },
                                          icon: const Icon(Icons.restart_alt),
                                          label: const Text("Reset"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox.shrink(),
                                ],

                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (selectedSidebar == "KORISNICI") {
                                      addUser(
                                        context,
                                        () => loadUsersFromApi(),
                                      );
                                    } else if (selectedSidebar == "ULOGE") {
                                      addRole(
                                        context,
                                        () => loadRolesFromApi(
                                          name:
                                              _roleSearchQuery.trim().isEmpty
                                                  ? null
                                                  : _roleSearchQuery.trim(),
                                        ),
                                      );
                                    } else if (selectedSidebar == "GRADOVI") {
                                      addCity(context, () {
                                        final name = _cityNameCtrl.text.trim();
                                        final zip = int.tryParse(
                                          _cityZipCtrl.text.trim(),
                                        );
                                        loadCitiesFromApi(
                                          name: name.isEmpty ? null : name,
                                          zipCode: zip,
                                        );
                                      });
                                    } else if (selectedSidebar == "DRŽAVE") {
                                      addCountry(context, () {
                                        final name =
                                            _countryNameCtrl.text.trim();
                                        final code =
                                            _countryCodeCtrl.text.trim();
                                        loadCountriesFromApi(
                                          name: name.isEmpty ? null : name,
                                          code: code.isEmpty ? null : code,
                                        );
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("DODAJ"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            if ((selectedSidebar == "ULOGE" && _loadingRoles) ||
                                (selectedSidebar == "KORISNICI" &&
                                    _loadingUsers) ||
                                (selectedSidebar == "GRADOVI" &&
                                    _loadingCities) ||
                                (selectedSidebar == "DRŽAVE" &&
                                    _loadingCountries))
                              const LinearProgressIndicator(minHeight: 3),
                            const SizedBox(height: 24),

                            Expanded(child: _buildContent()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userFilterField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool loading = false,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              loading
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : (controller.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onChanged(controller.text);
                        },
                      )),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _cityFilterField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool loading = false,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              loading
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : (controller.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onChanged(controller.text);
                        },
                      )),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget sidebarOption(String label, IconData icon) {
    final bool isActive = selectedSidebar == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSidebar = label;
        });
        if (label == "ULOGE") {
          _onRoleSearchChanged(_roleSearchCtrl.text);
        } else if (label == "KORISNICI") {
          _onUserFieldChanged();
        } else if (label == "GRADOVI") {
          _onCityFieldChanged();
        } else if (label == "DRŽAVE") {
          _onCountryFieldChanged();
        }
      },
      hoverColor: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey[700],
                backgroundColor:
                    isActive
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedSidebar) {
      case "KORISNICI":
        return users.isEmpty
            ? (_loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text("Nema rezultata.")))
            : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              children:
                  users.map((user) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: userCard(
                        user['id'],
                        user['name'],
                        user['email'],
                        user['roleName'],
                        Icons.person,
                        context,
                        user,
                        () => loadUsersFromApi(
                          firstName:
                              _firstNameCtrl.text.trim().isEmpty
                                  ? null
                                  : _firstNameCtrl.text.trim(),
                          lastName:
                              _lastNameCtrl.text.trim().isEmpty
                                  ? null
                                  : _lastNameCtrl.text.trim(),
                          username:
                              _usernameCtrl.text.trim().isEmpty
                                  ? null
                                  : _usernameCtrl.text.trim(),
                          email:
                              _emailCtrl.text.trim().isEmpty
                                  ? null
                                  : _emailCtrl.text.trim(),
                        ),
                      ),
                    );
                  }).toList(),
            );

      case "ULOGE":
        return roles.isEmpty
            ? (_loadingRoles
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text("Nema rezultata.")))
            : ListView.builder(
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.badge,
                      color: Color.fromARGB(255, 181, 156, 74),
                    ),
                    title: Text(
                      role['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(role['description']),
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            addRole(
                              context,
                              () => loadRolesFromApi(
                                name:
                                    _roleSearchQuery.trim().isEmpty
                                        ? null
                                        : _roleSearchQuery.trim(),
                              ),
                              initialData: role,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("Potvrda"),
                                    content: const Text(
                                      "Da li sigurno želiš obrisati ulogu?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text("Otkaži"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text("Obriši"),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              try {
                                await ApiService.deleteRole(role['id']);
                                loadRolesFromApi(
                                  name:
                                      _roleSearchQuery.trim().isEmpty
                                          ? null
                                          : _roleSearchQuery.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Uloga obrisana"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Greška pri brisanju: $e"),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

      case "GRADOVI":
        return cities.isEmpty
            ? (_loadingCities
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text("Nema rezultata.")))
            : ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_city,
                      color: Color.fromARGB(255, 181, 156, 74),
                    ),
                    title: Text(
                      city['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Poštanski broj: ${city['zipCode']}\nDržava: ${city['country'].name}",
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            addCity(context, () {
                              final name = _cityNameCtrl.text.trim();
                              final zip = int.tryParse(
                                _cityZipCtrl.text.trim(),
                              );
                              loadCitiesFromApi(
                                name: name.isEmpty ? null : name,
                                zipCode: zip,
                              );
                            }, initialData: city);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("Potvrda"),
                                    content: const Text(
                                      "Da li sigurno želiš obrisati grad?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text("Otkaži"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text("Obriši"),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              try {
                                await ApiService.deleteCity(city['id']);
                                final name = _cityNameCtrl.text.trim();
                                final zip = int.tryParse(
                                  _cityZipCtrl.text.trim(),
                                );
                                loadCitiesFromApi(
                                  name: name.isEmpty ? null : name,
                                  zipCode: zip,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Grad uspješno obrisan"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        "Exception: ",
                                        "",
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

      case "DRŽAVE":
        return countries.isEmpty
            ? (_loadingCountries
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text("Nema rezultata.")))
            : ListView.builder(
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.public,
                      color: Color.fromARGB(255, 181, 156, 74),
                    ),
                    title: Text(
                      country['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Kod: ${country['code']}"),
                    trailing: Wrap(
                      spacing: 12,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            addCountry(context, () {
                              final name = _countryNameCtrl.text.trim();
                              final code = _countryCodeCtrl.text.trim();
                              loadCountriesFromApi(
                                name: name.isEmpty ? null : name,
                                code: code.isEmpty ? null : code,
                              );
                            }, initialData: country);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("Potvrda"),
                                    content: const Text(
                                      "Da li sigurno želiš obrisati državu?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text("Otkaži"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text("Obriši"),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              try {
                                await ApiService.deleteCountry(country['id']);
                                final name = _countryNameCtrl.text.trim();
                                final code = _countryCodeCtrl.text.trim();
                                loadCountriesFromApi(
                                  name: name.isEmpty ? null : name,
                                  code: code.isEmpty ? null : code,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Država obrisana"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        "Exception: ",
                                        "",
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

      default:
        return const Center(child: Text("Odaberi stavku iz menija"));
    }
  }

  Widget navTab(String label, BuildContext context, {bool isActive = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (label == "KORISNICI") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserPage()),
            );
          } else if (label == "KNJIGE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BooksPage()),
            );
          } else if (label == "NARUDŽBE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrderPage()),
            );
          } else if (label == "FORUM") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ForumPage()),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color.fromARGB(255, 181, 156, 74)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget userCard(
    int id,
    String name,
    String email,
    String roleName,
    IconData icon,
    BuildContext context,
    Map<String, dynamic> user,
    VoidCallback refreshUsers,
  ) {
    return GestureDetector(
      onTap: () {
        fetchUserDetailsAndShow(context, id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 181, 156, 74)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    roleName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () async {
                try {
                  final details = await ApiService.getUserDetails(id);
                  addUser(context, refreshUsers, initialData: details);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Greška pri učitavanju korisnika: $e"),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Potvrda brisanja"),
                        content: const Text(
                          "Da li sigurno želiš obrisati korisnika?",
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
                            child: const Text("Obriši"),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  try {
                    await ApiService.deleteUser(id);
                    refreshUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Korisnik uspješno obrisan"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Greška pri brisanju: $e")),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void fetchUserDetailsAndShow(BuildContext context, int id) async {
    try {
      final user = await ApiService.getUserDetails(id);

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                    "Detalji korisnika",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Ime", "${user['firstName']} ${user['lastName']}"),
                    _infoRow("Email", user['email']),
                    _infoRow("Username", user['username']),
                    _infoRow("Telefon", user['phoneNumber']),
                    _infoRow("Datum rođenja", user['birthDate'].split('T')[0]),
                    _infoRow("Spol", user['gender']),
                    const Divider(),
                    _infoRow("Uloga", user['role']['name']),
                    _infoRow("Grad", user['city']['name']),
                  ],
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
                  child: const Text("Zatvori"),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
