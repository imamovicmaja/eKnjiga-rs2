import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/city.dart';
import '../models/country.dart';
import '../models/role.dart';

import '../models/book.dart';
import '../models/author.dart';
import '../models/category.dart';
import '../models/review.dart';

import '../models/comment.dart';
import '../models/commentAnswer.dart';
import '../models/userReport.dart';

import '../models/order.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:7114/api',
  );
  static String _authHeader = '';

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
    final roleName = data['role']?['name'];

    if (roleName == null) {
      throw ApiException('Nije moguće pronaći korisničku ulogu.');
    }

    if (roleName != 'Admin') {
      throw ApiException(
        'Pristup odbijen! Samo admin korisnici mogu se prijaviti.',
      );
    }

    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    _authHeader = basicAuth;
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final result = response.body.trim().toLowerCase() == 'true';
      if (!result) {
        throw ApiException(
          'Grad nije moguće obrisati jer je možda povezan s korisnicima.',
        );
      }
    } else {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju grada.');
      throw ApiException(msg);
    }
  }

  // ---------------- ROLES ----------------

  static Future<List<Role>> fetchRoles({String? name}) async {
    final uri = Uri.parse('$_apiBase/Role').replace(
      queryParameters: name != null && name.isNotEmpty ? {'name': name} : null,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final result = response.body.trim().toLowerCase() == 'true';
      if (!result) {
        throw ApiException('Greška pri brisanju uloge.');
      }
    } else {
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

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju korisnika.',
      );
      throw ApiException(msg);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUsers({
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
    void addQP(String key, dynamic v) {
      if (v == null) return;

      final s = v.toString().trim();
      if (s.isNotEmpty) qp[key] = s;
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

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dohvatu korisnika.',
      );
      throw ApiException(msg);
    }

    final decoded = jsonDecode(response.body);

    final List items;
    if (decoded is Map && decoded['items'] is List) {
      items = List.from(decoded['items']);
    } else if (decoded is List) {
      items = decoded;
    } else {
      throw ApiException('Neočekivan format odgovora za korisnike.');
    }

    int _parseId(dynamic v) {
      if (v is int) return v;
      final s = v?.toString();
      final parsed = int.tryParse(s ?? '');
      return parsed ?? 0;
    }

    String _safeJoinName(dynamic first, dynamic last, dynamic username) {
      final f = (first ?? '').toString().trim();
      final l = (last ?? '').toString().trim();
      final joined = [f, l].where((s) => s.isNotEmpty).join(' ');
      if (joined.isNotEmpty) return joined;
      final u = (username ?? '').toString().trim();
      return u.isNotEmpty ? u : '—';
    }

    return items.map<Map<String, dynamic>>((json) {
      final m = json as Map<String, dynamic>;
      return {
        'id': _parseId(m['id']),
        'name': _safeJoinName(m['firstName'], m['lastName'], m['username']),
        'email': (m['email'] ?? '').toString(),
        'roleName': (m['role']?['name'] ?? '').toString(),
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> getUserDetails(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Users/$id'),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final result = response.body.trim().toLowerCase() == 'true';
      if (!result) {
        throw ApiException(
          'Država nije mogla biti obrisana jer je možda povezana s gradovima.',
        );
      }
    } else {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju države.');
      throw ApiException(msg);
    }
  }

  // ---------------- CATEGORIES ----------------

  static Future<List<Category>> fetchCategories({String? name}) async {
    final uri = Uri.parse('$_apiBase/Category').replace(
      queryParameters: name != null && name.isNotEmpty ? {'name': name} : null,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final result = response.body.trim().toLowerCase() == 'true';
      if (!result) {
        throw ApiException(
          'Kategorija nije mogla biti obrisana jer je možda povezana s knjigama.',
        );
      }
    } else {
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

    final uri = Uri.parse('$_apiBase/Author').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final result = response.body.trim().toLowerCase() == 'true';
      if (!result) {
        throw ApiException(
          'Autor nije mogao biti obrisan jer je možda povezan s knjigama.',
        );
      }
    } else {
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

    final uri = Uri.parse('$_apiBase/Review').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri dohvatu recenzija.');
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode != 200) {
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

    final uri = Uri.parse('$_apiBase/Book').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response, 'Greška pri brisanju knjige.');
      throw ApiException(msg);
    }
  }

  static Future<void> createBook(Map<String, dynamic> bookData) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(bookData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri dodavanju knjige.',
      );
      throw ApiException(msg);
    }
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

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju knjige.',
      );
      throw ApiException(msg);
    }
  }

  // ---------------- COMMENTS ----------------

  static Future<List<Comment>> fetchComments({
    String? content,
    int? userId,
  }) async {
    final Map<String, String> queryParams = {};

    if (content != null && content.trim().isNotEmpty) {
      queryParams['content'] = content.trim();
    }

    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    final uri = Uri.parse('$_apiBase/Comment').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data =
          decoded is Map && decoded['items'] is List
              ? decoded['items']
              : <dynamic>[];

      return data
          .map<Comment>((json) => Comment.fromJson(json))
          .toList();
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode != 200) {
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
  }) async {
    final Map<String, String> queryParams = {};

    if (content != null && content.trim().isNotEmpty) {
      queryParams['content'] = content.trim();
    }
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }
    if (parentCommentId != null) {
      queryParams['parentCommentId'] = parentCommentId.toString();
    }

    final uri = Uri.parse('$_apiBase/CommentAnswer').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode != 200) {
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
  }) async {
    final Map<String, String> queryParams = {};

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

    final uri = Uri.parse('$_apiBase/UserReport').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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
    final updatedBody = {
      'reason': report.reason,
      'status': newStatus,
      'userReportedId': report.userReported.id,
      'reportedByUserId': report.reportedByUser.id,
    };

    final response = await http.put(
      Uri.parse('$_apiBase/UserReport/${report.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(updatedBody),
    );

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
  }) async {
    final params = <String, String>{};

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

    final uri = Uri.parse('$_apiBase/Order').replace(
      queryParameters: params,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

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

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(
        response,
        'Greška pri ažuriranju narudžbe.',
      );
      throw ApiException(msg);
    }
  }
}
