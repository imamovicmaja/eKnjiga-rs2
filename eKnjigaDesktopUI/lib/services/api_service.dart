import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../models/city.dart';
import '../models/country.dart';
import '../models/role.dart';

import '../models/book.dart';
import '../models/author.dart';
import '../models/category.dart';
import '../models/review.dart';
import '../models/comment.dart' hide User;
import '../models/commentAnswer.dart' hide User;
import '../models/userReport.dart' hide User;
import '../models/order_report.dart';
import '../models/user.dart';

import 'dart:typed_data';

import '../models/order.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiUnauthorizedException implements Exception {
  final String message;

  ApiUnauthorizedException([
    this.message = 'Sesija je istekla. Prijavite se ponovo.',
  ]);

  @override
  String toString() => message;
}

class ApiService {
  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:7114/api',
  );
  static String _authHeader = '';

  static String? roleName;
  static bool get isAdmin => roleName == "Admin";
  static bool get isEmployee => roleName == "Employee";

  /// Poziva se kada backend vrati 401 Unauthorized.
  /// U main.dart se ovdje postavlja redirect na login ekran.
  static void Function()? onUnauthorized;

  static Future<void> clearSession() async {
    _authHeader = '';
    roleName = null;
  }

  static Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      await clearSession();
      onUnauthorized?.call();
      throw ApiUnauthorizedException();
    }
  }

  static Future<void> _handleUnauthorizedStreamed(
    http.StreamedResponse response,
  ) async {
    if (response.statusCode == 401) {
      await clearSession();
      onUnauthorized?.call();
      throw ApiUnauthorizedException();
    }
  }

  static String _extractErrorMessage(
    http.Response response,
    String defaultMessage,
  ) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {}

    return defaultMessage;
  }

  static Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Greška pri prijavi: ${response.body}');
    }

    final data = jsonDecode(response.body);

    roleName = (data['role'] as String?)?.trim();

    if (roleName == null || roleName!.isEmpty) {
      throw ApiException('Nije moguće pronaći korisničku ulogu.');
    }

    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw ApiException('JWT token nije vraćen sa servera.');
    }

    _authHeader = 'Bearer $token';
  }

  static Future<void> logout() async {
    final currentAuthHeader = _authHeader;

    try {
      if (currentAuthHeader.isNotEmpty) {
        await http.post(
          Uri.parse('$_apiBase/Auth/logout'),
          headers: {'Authorization': currentAuthHeader},
        );
      }
    } catch (_) {
    } finally {
      await clearSession();
    }
  }

  //-----------------PDF---------------------
  static Future<Uint8List> getBookPdf(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Book/$id/pdf'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw Exception('Greška pri dohvaćanju PDF-a');
    }

    return response.bodyBytes;
  }

  // ---------------- CITIES ----------------
  static Future<List<City>> fetchCities({
    String? name,
    int? zipCode,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};
    void addQP(String key, String? v) {
      if (v != null && v.trim().isNotEmpty) qp[key] = v.trim();
    }

    addQP('Name', name);
    if (zipCode != null) qp['ZipCode'] = zipCode.toString();
    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/City',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu gradova.');
      throw ApiException(msg);
    }

    final decoded = json.decode(response.body);
    final List data;
    if (decoded is Map && decoded['items'] is List) {
      data = List.from(decoded['items']);
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za gradove.');
    }

    return data.map((json) => City.fromJson(json)).toList();
  }

  static Future<void> createCity(Map<String, dynamic> cityData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/City'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(cityData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(response, 'Greška pri dodavanju grada.');
      throw ApiException(msg);
    }
  }

  static Future<void> updateCity(
    int id,
    Map<String, dynamic> updatedCity,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/City/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedCity),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju grada.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteCity(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/City/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju grada.');
      throw ApiException(msg);
    }
  }

  // ---------------- ROLES ----------------

  static Future<List<Role>> fetchRoles({
    String? name,
    int? page,
    int? pageSize,
  }) async {
    final qp = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      qp['name'] = name.trim();
    }

    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();

    final uri = Uri.parse(
      '$_apiBase/Role',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];

      return data.map((json) => Role.fromJson(json)).toList();
    } else {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu uloga.');
      throw ApiException(msg);
    }
  }

  static Future<void> createRole(Map<String, dynamic> roleData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(roleData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(response, 'Greška pri dodavanju uloge.');
      throw ApiException(msg);
    }
  }

  static Future<void> updateRole(
    int id,
    Map<String, dynamic> updatedRole,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Role/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedRole),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju uloge.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteRole(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Role/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju uloge.');
      throw ApiException(msg);
    }
  }

  // ---------------- USERS ----------------

  static Future<void> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(userData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju korisnika.',
      );
      throw ApiException(msg);
    }
  }

  static Future<List<User>> fetchUsers({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    int? roleId,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};

    void addQP(String key, Object? value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isNotEmpty) qp[key] = text;
    }

    addQP('FirstName', firstName);
    addQP('LastName', lastName);
    addQP('Username', username);
    addQP('Email', email);
    addQP('RoleId', roleId);

    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/Users',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu korisnika.',
      );
      throw ApiException(msg);
    }

    final decoded = jsonDecode(response.body);

    final List data;
    if (decoded is Map && decoded['items'] is List) {
      data = List.from(decoded['items']);
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za korisnike.');
    }

    return data
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<User> getUserDetails(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Users/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu korisnika.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> updateUser(
    int id,
    Map<String, dynamic> updatedUser,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedUser),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju korisnika.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Users/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju korisnika.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- COUNTRIES ----------------

  static Future<List<Country>> fetchCountries({
    String? name,
    String? code,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};
    void addQP(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) qp[k] = v.trim();
    }

    addQP('Name', name);
    addQP('Code', code);
    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/Country',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu država.');
      throw ApiException(msg);
    }

    final decoded = json.decode(response.body);
    final List data =
        (decoded is Map && decoded['items'] is List)
            ? List.from(decoded['items'])
            : (decoded is List)
            ? decoded
            : throw ApiException('Neočekivan format odgovora za države.');

    return data.map((json) => Country.fromJson(json)).toList();
  }

  static Future<void> createCountry(Map<String, dynamic> countryData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Country'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(countryData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju države.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> updateCountry(
    int id,
    Map<String, dynamic> updatedCountry,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Country/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedCountry),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju države.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteCountry(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Country/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju države.');
      throw ApiException(msg);
    }
  }

  // ---------------- CATEGORIES ----------------

  static Future<List<Category>> fetchCategories({
    String? name,
    int? page,
    int? pageSize,
  }) async {
    final qp = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      qp['name'] = name.trim();
    }

    if (page != null) {
      qp['Page'] = page.toString();
    }

    if (pageSize != null) {
      qp['PageSize'] = pageSize.toString();
    }

    final uri = Uri.parse(
      '$_apiBase/Category',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];

      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu kategorija.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> createCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Category'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(categoryData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju kategorije.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> updateCategory(
    int id,
    Map<String, dynamic> updatedCategory,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Category/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedCategory),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju kategorije.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Category/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju kategorije.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- AUTHORS ----------------

  static Future<List<Author>> fetchAuthors({
    String? firstName,
    String? lastName,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};

    void addQP(String key, String? v) {
      if (v != null && v.trim().isNotEmpty) qp[key] = v.trim();
    }

    addQP('FirstName', firstName);
    addQP('LastName', lastName);
    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/Author',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu autora.');
      throw ApiException(msg);
    }

    final decoded = json.decode(response.body);
    final List data;
    if (decoded is Map && decoded['items'] is List) {
      data = List.from(decoded['items']);
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za autore.');
    }

    return data.map((json) => Author.fromJson(json)).toList();
  }

  static Future<void> createAuthor(Map<String, dynamic> authorData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Author'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(authorData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String message = 'Greška pri dodavanju autora.';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message')) {
        message = data['message'] as String;
      }
    } catch (_) {}

    throw ApiException(message);
  }

  static Future<void> updateAuthor(
    int id,
    Map<String, dynamic> updatedAuthor,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Author/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedAuthor),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju autora.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteAuthor(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Author/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju autora.');
      throw ApiException(msg);
    }
  }

  // ---------------- REVIEWS ----------------

  static Future<List<Review>> fetchReviews({
    int? bookId,
    int? userId,
    int? rating,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};

    void addQP(String key, String? v) {
      if (v != null && v.toString().trim().isNotEmpty) {
        qp[key] = v.toString().trim();
      }
    }

    if (bookId != null) qp['BookId'] = bookId.toString();
    if (userId != null) qp['UserId'] = userId.toString();
    if (rating != null) qp['Rating'] = rating.toString();
    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/Review',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu recenzija.',
      );
      throw ApiException(msg);
    }

    final decoded = json.decode(response.body);

    final List data;
    if (decoded is Map && decoded['items'] is List) {
      data = List.from(decoded['items']);
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za recenzije.');
    }

    return data.map((json) => Review.fromJson(json)).toList();
  }

  static Future<void> deleteReview(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Review/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju recenzije.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- BOOKS ----------------

  static Future<List<Book>> fetchBooks({
    String? name,
    String? description,
    int? categoryId,
    int? page,
    int? pageSize,
    bool includeTotalCount = false,
  }) async {
    final qp = <String, String>{};

    void addQP(String key, String? v) {
      if (v != null && v.trim().isNotEmpty) qp[key] = v.trim();
    }

    addQP('Name', name);
    addQP('Description', description);
    if (categoryId != null) qp['CategoryId'] = categoryId.toString();
    if (page != null) qp['Page'] = page.toString();
    if (pageSize != null) qp['PageSize'] = pageSize.toString();
    if (includeTotalCount) qp['IncludeTotalCount'] = 'true';

    final uri = Uri.parse(
      '$_apiBase/Book',
    ).replace(queryParameters: qp.isEmpty ? null : qp);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu knjiga.');
      throw ApiException(msg);
    }

    final decoded = json.decode(response.body);
    final List data;
    if (decoded is Map && decoded['items'] is List) {
      data = List.from(decoded['items']);
    } else if (decoded is List) {
      data = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za knjige.');
    }

    return data.map((json) => Book.fromJson(json)).toList();
  }

  static Future<void> deleteBook(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Book/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju knjige.');
      throw ApiException(msg);
    }
  }

  static Future<Book> createBook(Map<String, dynamic> bookData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(bookData),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju knjige.',
      );
      throw ApiException(msg);
    }

    if (response.body.isEmpty) {
      throw ApiException('Knjiga je dodana, ali API nije vratio podatke.');
    }

    return Book.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> updateBook(
    int id,
    Map<String, dynamic> updatedBook,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Book/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedBook),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju knjige.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> uploadBookCover(
    int bookId,
    Uint8List bytes,
    String fileName,
  ) async {
    final uri = Uri.parse('$_apiBase/Book/$bookId/cover');

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = _authHeader;

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await request.send();

    await _handleUnauthorizedStreamed(response);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ApiException('Greška pri uploadu slike: $body');
    }
  }

  static Future<void> uploadBookPdf(
    int bookId,
    Uint8List bytes,
    String fileName,
  ) async {
    final uri = Uri.parse('$_apiBase/Book/$bookId/pdf-upload');

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = _authHeader;

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await request.send();

    await _handleUnauthorizedStreamed(response);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ApiException('Greška pri uploadu PDF-a: $body');
    }
  }

  static String getImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';

    if (relativeUrl.startsWith('http')) return relativeUrl;

    final uri = Uri.parse(_apiBase);
    final base = '${uri.scheme}://${uri.host}:${uri.port}';

    return '$base$relativeUrl';
  }

  static Future<Book> getBookById(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Book/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw Exception('Greška pri dohvaćanju knjige');
    }

    final data = jsonDecode(response.body);
    return Book.fromJson(data);
  }

  // ---------------- COMMENTS ----------------

  static Future<List<Comment>> fetchComments({
    String? content,
    int? userId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (content != null && content.trim().isNotEmpty) {
      queryParams['content'] = content.trim();
    }

    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    final uri = Uri.parse(
      '$_apiBase/Comment',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];

      return data.map<Comment>((json) => Comment.fromJson(json)).toList();
    } else {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu komentara.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteComment(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Comment/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju komentara.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- COMMENT ANSWERS ----------------

  static Future<List<CommentAnswer>> fetchCommentAnswers({
    String? content,
    int? userId,
    int? parentCommentId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (content != null && content.trim().isNotEmpty) {
      queryParams['content'] = content.trim();
    }
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }
    if (parentCommentId != null) {
      queryParams['parentCommentId'] = parentCommentId.toString();
    }

    final uri = Uri.parse(
      '$_apiBase/CommentAnswer',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];

      return data
          .map<CommentAnswer>((json) => CommentAnswer.fromJson(json))
          .toList();
    } else {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu odgovora.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> deleteCommentAnswer(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/CommentAnswer/$id'),
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju odgovora.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- USER REPORTS ----------------

  static Future<List<UserReport>> fetchUserReports({
    String? reason,
    int? status,
    int? userReportedId,
    int? reportedByUserId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (reason != null && reason.trim().isNotEmpty) {
      queryParams['reason'] = reason.trim();
    }
    if (status != null) {
      queryParams['status'] = status.toString();
    }
    if (userReportedId != null) {
      queryParams['userReportedId'] = userReportedId.toString();
    }
    if (reportedByUserId != null) {
      queryParams['reportedByUserId'] = reportedByUserId.toString();
    }

    final uri = Uri.parse(
      '$_apiBase/UserReport',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];
      return data.map<UserReport>((json) => UserReport.fromJson(json)).toList();
    } else {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu prijava.');
      throw ApiException(msg);
    }
  }

  static Future<void> updateUserReport(UserReport report, int newStatus) async {
    final updatedBody = {'status': newStatus};

    final response = await http.put(
      Uri.parse('$_apiBase/UserReport/${report.id}/process'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedBody),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri izmjeni statusa prijave.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- ORDERS ----------------

  static Future<List<OrderResponse>> fetchOrders({
    int? type,
    bool includeTotalCount = true,
    int? userId,
    double? totalPrice,
    int? orderStatus,
    int? paymentStatus,
    bool? excludeCompleted,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (type != null) {
      params['type'] = type.toString();
    }
    if (userId != null) {
      params['userId'] = userId.toString();
    }
    if (totalPrice != null) {
      params['totalPrice'] = totalPrice.toString();
    }
    if (orderStatus != null) {
      params['orderStatus'] = orderStatus.toString();
    }
    if (paymentStatus != null) {
      params['paymentStatus'] = paymentStatus.toString();
    }
    if (excludeCompleted != null) {
      params['excludeCompleted'] = excludeCompleted.toString();
    }
    if (includeTotalCount) {
      params['includeTotalCount'] = 'true';
    }

    final uri = Uri.parse('$_apiBase/Order').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu narudžbi.',
      );
      throw ApiException(msg);
    }

    final decoded = jsonDecode(response.body);
    final List items = (decoded['items'] as List?) ?? [];

    return items.map((e) => OrderResponse.fromJson(e)).toList();
  }

  static Future<void> deleteOrder(int id) async {
    final uri = Uri.parse('$_apiBase/Order/$id');

    final response = await http.delete(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri brisanju narudžbe.',
      );
      throw ApiException(msg);
    }
  }

  static Future<void> updateOrder(
    int id,
    Map<String, dynamic> updatedOrder,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Order/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedOrder),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju narudžbe.',
      );
      throw ApiException(msg);
    }
  }

  static Future<OrderReport> fetchOrderReport({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, String>{};

    if (dateFrom != null) {
      params['dateFrom'] = dateFrom.toIso8601String();
    }

    if (dateTo != null) {
      params['dateTo'] = dateTo.toIso8601String();
    }

    final uri = Uri.parse(
      '$_apiBase/Order/report',
    ).replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu izvještaja.',
      );
      throw ApiException(msg);
    }

    final decoded = jsonDecode(response.body);
    return OrderReport.fromJson(decoded);
  }
}
