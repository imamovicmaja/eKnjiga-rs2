import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import '../core/config/config.dart';
import '../models/comment.dart';
import '../models/commentAnswer.dart';
import '../models/category.dart';
import '../models/book.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/paypal.dart';
import '../models/favorites.dart';
import '../models/app_notification.dart';
import '../models/city.dart';
import '../models/user_profile.dart';

import 'package:shared_preferences/shared_preferences.dart';

class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;
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
  static const String _apiBase = Config.apiBase;

  static String _authHeader = '';
  static String _jwtToken = '';
  static int userID = 0;

  static String? roleName;
  static bool get isAdmin => (roleName?.toLowerCase().trim() == 'admin');

  /// Poziva se kada backend vrati 401 Unauthorized.
  /// U main.dart se ovdje postavlja redirect na login ekran.
  static void Function()? onUnauthorized;

  // ---------- Session helpers ----------

  static Future<void> _saveSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('userID', userID);
    await sp.setString('roleName', roleName ?? '');
    await sp.setString('_authHeader', _authHeader);
    await sp.setString('jwtToken', _jwtToken);
  }

  static Future<void> restoreSession() async {
    final sp = await SharedPreferences.getInstance();
    userID = sp.getInt('userID') ?? 0;
    roleName = sp.getString('roleName');
    _authHeader = sp.getString('_authHeader') ?? '';
    _jwtToken = sp.getString('jwtToken') ?? '';
  }

  static Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('userID');
    await sp.remove('roleName');
    await sp.remove('_authHeader');
    await sp.remove('jwtToken');
    userID = 0;
    roleName = null;
    _authHeader = '';
    _jwtToken = '';
  }

  static Future<void> logout() async {
    await _ensureAuth();

    if (_authHeader.isNotEmpty) {
      await http.post(
        Uri.parse('$_apiBase/Users/logout'),
        headers: await _headersNoBody(),
      );
    }

    await clearSession();
  }

  // ---------- Auth headers (AUTO for every route except login) ----------

  static Future<void> _ensureAuth() async {
    if (_authHeader.isNotEmpty) return;
    await restoreSession();
  }

  static Future<Map<String, String>> _headersJson({
    bool includeContentType = true,
  }) async {
    await _ensureAuth();
    final h = <String, String>{};

    if (includeContentType) {
      h['Content-Type'] = 'application/json';
    }
    if (_authHeader.isNotEmpty) {
      h['Authorization'] = _authHeader;
    }
    return h;
  }

  static Future<Map<String, String>> _headersNoBody() async {
    await _ensureAuth();
    final h = <String, String>{};
    if (_authHeader.isNotEmpty) {
      h['Authorization'] = _authHeader;
    }
    return h;
  }

  static Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      await clearSession();
      onUnauthorized?.call();
      throw ApiUnauthorizedException();
    }
  }

  // ---------- Login (ONLY route without auth header) ----------

  static Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('Greška pri prijavi.', response.body);
    }

    final data = jsonDecode(response.body);

    userID = data["userId"];
    roleName = (data["role"] as String?)?.trim();

    _jwtToken = data["token"];

    _authHeader = 'Bearer $_jwtToken';

    await _saveSession();
  }

  //----------- Register ----------

  static Future<void> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$_apiBase/Users/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw _apiException(
        'Registracija nije uspjela. Provjerite unesene podatke.',
        response.body,
      );
    }
  }

  // ---------- Comments ----------

  static Future<PagedResult<Comment>> fetchCommentsPaged({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_apiBase/Comment').replace(
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'includeTotalCount': 'true',
      },
    );

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['items'] ?? [];

      return PagedResult<Comment>(
        items: data.map<Comment>((json) => Comment.fromJson(json)).toList(),
        totalCount: decoded['totalCount'] ?? data.length,
        page: decoded['page'] ?? page,
        pageSize: decoded['pageSize'] ?? pageSize,
      );
    } else {
      throw _apiException('Greška pri dohvatu komentara.', response.body);
    }
  }

  static Future<void> addComment(String content) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Comment'),
      headers: await _headersJson(),
      body: jsonEncode({'content': content}),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('Greška pri dodavanju komentara.', response.body);
    }
  }

  static Future<void> deleteComment(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/Comment/$id'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _apiException('Greška pri brisanju komentara.', response.body);
    }
  }

  // ---------- Comment Answers ----------

  static Future<List<CommentAnswer>> fetchCommentAnswers() async {
    final response = await http.get(
      Uri.parse('$_apiBase/CommentAnswer'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['items'];
      return data
          .map<CommentAnswer>((json) => CommentAnswer.fromJson(json))
          .toList();
    } else {
      throw _apiException('Greška pri dohvatu odgovora.', response.body);
    }
  }

  static Future<void> addCommentAnswer(
    int parentCommentId,
    String content, {
    int? replyToCommentId,
  }) async {
    final body = {'content': content, 'parentCommentId': parentCommentId};

    if (replyToCommentId != null) {
      body['replyToCommentId'] = replyToCommentId;
    }

    final response = await http.post(
      Uri.parse('$_apiBase/CommentAnswer'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('Greška pri dodavanju odgovora.', response.body);
    }
  }

  static Future<void> deleteCommentAnswer(int id) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/CommentAnswer/$id'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _apiException('Greška pri brisanju odgovora.', response.body);
    }
  }

  // ---------- Comment Reactions ----------

  static Future<void> addCommentReaction({
    int? commentId,
    int? commentAnswerId,
    required bool isLike,
  }) async {
    final Map<String, dynamic> body = {
      'isLike': isLike,
      if (commentId != null) 'commentId': commentId,
      if (commentAnswerId != null) 'commentAnswerId': commentAnswerId,
    };

    final resp = await http.post(
      Uri.parse('$_apiBase/CommentReaction'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw _apiException('Greška pri reakciji.', resp.body);
    }
  }

  static Future<void> deleteCommentReaction({
    int? commentId,
    int? commentAnswerId,
  }) async {
    final Map<String, dynamic> body = {
      if (commentId != null) 'commentId': commentId,
      if (commentAnswerId != null) 'commentAnswerId': commentAnswerId,
    };

    final resp = await http.delete(
      Uri.parse('$_apiBase/CommentReaction'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _apiException('Greška pri brisanju reakcije.', resp.body);
    }
  }

  static Future<Map<String, dynamic>?> fetchMyReactions(int userId) async {
    final resp = await http.get(
      Uri.parse('$_apiBase/CommentReaction?UserId=$userId'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200) {
      throw _apiException('Greška pri dohvatu mojih reakcija.', resp.body);
    }

    if (resp.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<Map<String, dynamic>> items =
        (data['items'] as List? ?? []).cast<Map<String, dynamic>>();

    return {'items': items};
  }

  //-----------PDF-------------------

  static Future<Uint8List> getBookPdf(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Book/$id/pdf'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 404) {
      throw Exception('NOT_PAID');
    }

    await _handleUnauthorized(response);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('NO_ACCESS');
    }

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw Exception('ERROR');
    }

    return response.bodyBytes;
  }

  // ---------- Categories ----------

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$_apiBase/Category'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw _apiException('Greška pri dohvatanju kategorija.', response.body);
    }
  }

  //----------- Cities ---------

  static Future<List<City>> getCities() async {
    final response = await http.get(
      Uri.parse('$_apiBase/City'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['items'] ?? [];

      return data.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw _apiException('Greška pri dohvatanju gradova.', response.body);
    }
  }

  // ---------- Books ----------

  static String getImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';

    if (relativeUrl.startsWith('http')) return relativeUrl;

    final serverBase = _apiBase.replaceFirst('/api', '');
    return '$serverBase$relativeUrl';
  }

  static Future<List<Book>> fetchBooks({int? categoryId}) async {
    final uri = Uri.parse('$_apiBase/Book').replace(
      queryParameters:
          categoryId != null ? {'CategoryId': categoryId.toString()} : null,
    );

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw _apiException('Greška pri dohvatu knjiga.', response.body);
    }
  }

  static Future<Book> getBookById(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBase/Book/$id'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw Exception('Greška pri dohvaćanju knjige');
    }

    return Book.fromJson(jsonDecode(response.body));
  }

  static Future<List<Book>> fetchRecommendedBooks({int? categoryId}) async {
    final queryParams = <String, String>{};

    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }

    final uri = Uri.parse(
      '$_apiBase/Book/recommended',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    print("QUERY PARAMS: $queryParams");
    print("URL: $uri");

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw _apiException(
        'Greška pri dohvatu preporučenih knjiga.',
        response.body,
      );
    }
  }

  static Future<List<Book>> fetchNewBooks() async {
    final response = await http.get(
      Uri.parse('$_apiBase/Book/new'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw _apiException('Greška pri dohvatu knjiga.', response.body);
    }
  }

  static Future<List<Book>> fetchUserBooks() async {
    final url = Uri.parse('$_apiBase/Users/$userID');

    final resp = await http.get(url, headers: await _headersNoBody());

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200) {
      throw _apiException('Greška pri dohvatu korisničkih knjiga.', resp.body);
    }

    final decoded = json.decode(resp.body);
    final List items = decoded['userBooks'] as List;

    Favorites.I.items.clear();

    final books = <Book>[];

    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final book = Book.fromJson(map['book'] as Map<String, dynamic>);
      books.add(book);

      if (map['isFavorite'] == true) {
        Favorites.I.add(book);
      }
    }

    return books;
  }

  // ---------- Users ----------

  static Future<UserProfile> fetchUserById() async {
    final resp = await http.get(
      Uri.parse('$_apiBase/Users/$userID'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200) {
      throw _apiException('Greška pri dohvatu korisnika.', resp.body);
    }

    return UserProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  static String _extractErrorMessage(String body) {
    if (body.trim().isEmpty) {
      return 'Profil nije moguće ažurirati. Provjerite unesene podatke.';
    }

    try {
      final data = jsonDecode(body);

      if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;

        final messages =
            errors.values
                .whereType<List>()
                .expand((x) => x)
                .map((x) => x.toString())
                .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      if (data is Map && data['title'] != null) {
        return data['title'].toString();
      }
    } catch (_) {}

    return body;
  }

  static Exception _apiException(String fallback, String body) {
    final parsed = _extractErrorMessage(body).trim();

    if (parsed.isEmpty || parsed == body.trim()) {
      return Exception(fallback);
    }

    return Exception(parsed);
  }

  static Future<void> updateUser({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String phoneNumber,
    required int? cityId,
    String? oldPassword,
    String? password,
    String? confirmPassword,
  }) async {
    final current = await fetchUserById();

    final body = {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "username": username,
      "phoneNumber": phoneNumber,
      "birthDate": current.birthDate?.toIso8601String(),
      "gender": current.gender,
      if (cityId != null) "cityId": cityId,
    };

    if (password != null && password.trim().isNotEmpty) {
      body["password"] = password.trim();
    }

    if (oldPassword != null && oldPassword.trim().isNotEmpty) {
      body["oldPassword"] = oldPassword.trim();
    }

    if (confirmPassword != null && confirmPassword.trim().isNotEmpty) {
      body["confirmPassword"] = confirmPassword.trim();
    }

    final resp = await http.put(
      Uri.parse('$_apiBase/Users/$userID/profile'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _apiException(
        'Profil nije moguće ažurirati. Provjerite unesene podatke.',
        resp.body,
      );
    }
  }

  static Future<void> setFavorite(int bookId, bool isFavorite) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Users/books/$bookId/favorite'),
      headers: await _headersJson(),
      body: jsonEncode(isFavorite),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri postavljanju favorita.', response.body);
    }
  }

  static Future<bool> getFavorite(int bookId) async {
    final resp = await http.get(
      Uri.parse('$_apiBase/Users/books/$bookId/favorite'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as bool;
    }

    throw _apiException('Greška pri dohvaćanju favorita.', resp.body);
  }

  static Future<bool> hasPurchasedPdf(int bookId) async {
    await _ensureAuth();

    if (userID == 0) return false;

    final response = await http.get(
      Uri.parse('$_apiBase/Users/$userID'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException(
        'Greška pri provjeri kupljenih PDF knjiga.',
        response.body,
      );
    }

    final data = jsonDecode(response.body);

    final userBooks = (data['userBooks'] as List?) ?? [];

    return userBooks.any((x) {
      final book = x['book'];
      return book != null && book['id'] == bookId;
    });
  }

  // ---------- Orders ----------

  static Future<int> createOrder({
    required int type,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    final body = {"type": type, "orderItems": orderItems};

    final response = await http.post(
      Uri.parse('$_apiBase/Order'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('Greška pri kreiranju narudžbe.', response.body);
    }

    final data = jsonDecode(response.body);
    return data['id'];
  }

  static Future<PagedResult<OrderResponse>> fetchOrdersPaged({
    int page = 1,
    int pageSize = 20,
    int? type,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'includeTotalCount': 'true',
    };

    if (type != null) params['type'] = type.toString();
    if (userID > 0) params['userId'] = userID.toString();

    final uri = Uri.parse('$_apiBase/Order').replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri dohvatu narudžbi.', response.body);
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['items'] ?? [];

    return PagedResult<OrderResponse>(
      items: data.map((e) => OrderResponse.fromJson(e)).toList(),
      totalCount: decoded['totalCount'] ?? data.length,
      page: decoded['page'] ?? page,
      pageSize: decoded['pageSize'] ?? pageSize,
    );
  }

  static Future<List<OrderResponse>> fetchOrders({int? type}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type.toString();
    if (userID > 0) params['userId'] = userID.toString();

    final uri = Uri.parse('$_apiBase/Order').replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri dohvatu narudžbi.', response.body);
    }

    final decoded = jsonDecode(response.body);
    final List items = (decoded['items'] as List?) ?? [];
    return items.map((e) => OrderResponse.fromJson(e)).toList();
  }

  static Future<void> cancelOrder(int orderId) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Order/$orderId/cancel'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri otkazivanju narudžbe.', response.body);
    }
  }

  // ---------- Reviews ----------

  static Future<void> createReview({
    required double rating,
    required int bookId,
  }) async {
    final body = {"rating": rating, "bookId": bookId};

    final response = await http.post(
      Uri.parse('$_apiBase/Review'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('Greška pri kreiranju recenzije.', response.body);
    }
  }

  static Future<UserReviewResult?> fetchUserReview({
    required int bookId,
  }) async {
    final url = '$_apiBase/Review?BookId=$bookId&UserId=$userID';

    final response = await http.get(
      Uri.parse(url),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri dohvaćanju recenzije.', response.body);
    }

    final data = jsonDecode(response.body);

    if (data['items'] == null || data['items'].isEmpty) {
      return null;
    }

    final item = data['items'][0];
    return UserReviewResult(item['id'], (item['rating'] as num).toDouble());
  }

  static Future<void> updateReview({
    required int reviewId,
    required double rating,
  }) async {
    final body = {"rating": rating};

    final response = await http.put(
      Uri.parse('$_apiBase/Review/$reviewId'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri izmjeni recenzije.', response.body);
    }
  }

  // ---------- Reports ----------

  static Future<void> reportComment({
    required int? userReportedId,
    required String? reason,
  }) async {
    final body = {'reason': reason, 'userReportedId': userReportedId};

    final resp = await http.post(
      Uri.parse('$_apiBase/UserReport'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw _apiException('Greška pri prijavi komentara.', resp.body);
    }
  }

  //----------- Notifications ---------

  static Future<List<AppNotification>> fetchNotifications() async {
    final response = await http.get(
      Uri.parse('$_apiBase/Notification'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri dohvaćanju notifikacija.', response.body);
    }

    final List data = jsonDecode(response.body);

    return data.map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<PagedResult<AppNotification>> fetchNotificationsPaged({
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse('$_apiBase/Notification').replace(
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'includeTotalCount': 'true',
      },
    );

    final response = await http.get(uri, headers: await _headersNoBody());

    await _handleUnauthorized(response);

    if (response.statusCode != 200) {
      throw _apiException('Greška pri dohvaćanju notifikacija.', response.body);
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['items'] ?? [];

    return PagedResult<AppNotification>(
      items: data.map((e) => AppNotification.fromJson(e)).toList(),
      totalCount: decoded['totalCount'] ?? data.length,
      page: decoded['page'] ?? page,
      pageSize: decoded['pageSize'] ?? pageSize,
    );
  }

  static Future<void> markNotificationAsRead(int id) async {
    final response = await http.put(
      Uri.parse('$_apiBase/Notification/$id/read'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _apiException(
        'Greška pri označavanju notifikacije.',
        response.body,
      );
    }
  }

  static Future<int> fetchUnreadNotificationsCount() async {
    final response = await http.get(
      Uri.parse('$_apiBase/Notification/unread-count'),
      headers: await _headersNoBody(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode == 200) {
      return int.tryParse(response.body) ?? 0;
    }

    throw _apiException(
      'Greška pri dohvatanju broja nepročitanih notifikacija.',
      response.body,
    );
  }

  // ---------- PayPal ----------

  static String get paypalReturnUrlPrefix => Config.paypalReturnUrl;
  static String get paypalCancelUrlPrefix => Config.paypalCancelUrl;

  static Future<PaypalCreateOrderResult> paypalCreateOrder({
    required int orderId,
    required double amount,
    String currency = 'EUR',
  }) async {
    final body = {"orderId": orderId, "amount": amount, "currency": currency};

    final response = await http.post(
      Uri.parse('$_apiBase/Paypal/create-order'),
      headers: await _headersJson(),
      body: jsonEncode(body),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('PayPal create-order greška.', response.body);
    }

    return PaypalCreateOrderResult.fromJson(jsonDecode(response.body));
  }

  static Future<void> paypalCaptureOrder(String paypalOrderId) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Paypal/capture-order/$paypalOrderId'),
      headers: await _headersJson(),
    );

    await _handleUnauthorized(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiException('PayPal capture-order greška.', response.body);
    }
  }

  // ---------- Profile image upload (multipart) ----------

  static Future<void> updateProfileImage(File file) async {
    await _ensureAuth();
    if (userID == 0) {
      throw Exception('Niste prijavljeni.');
    }

    final uri = Uri.parse('$_apiBase/Users/$userID/profile-image');
    final request = http.MultipartRequest('PUT', uri);

    if (_authHeader.isNotEmpty) {
      request.headers['Authorization'] = _authHeader;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: _guessImageContentType(file.path),
      ),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _apiException('Greška pri uploadu slike.', resp.body);
    }
  }

  static Future<void> updateProfileImagePath({required String path}) async {
    await _ensureAuth();
    if (userID == 0) {
      throw Exception('Niste prijavljeni.');
    }

    final uri = Uri.parse('$_apiBase/Users/$userID/profile-image');
    final request = http.MultipartRequest('PUT', uri);

    if (_authHeader.isNotEmpty) {
      request.headers['Authorization'] = _authHeader;
    }

    final lower = path.toLowerCase();
    final isPng = lower.endsWith('.png');
    final isJpg = lower.endsWith('.jpg') || lower.endsWith('.jpeg');

    // Kamera/emulator nekad vrati čudan path bez ekstenzije -> forsiraj jpg
    final filename = isPng ? 'profile.png' : 'profile.jpg';
    final contentType =
        isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        path,
        filename: filename,
        contentType: contentType,
      ),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    await _handleUnauthorized(resp);

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _apiException('Greška pri uploadu slike.', resp.body);
    }
  }

  static MediaType _guessImageContentType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return MediaType('image', 'png');
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return MediaType('application', 'octet-stream');
  }
}
