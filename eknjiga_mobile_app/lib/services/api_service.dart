import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/comment.dart';
import '../models/commentAnswer.dart';
import '../models/category.dart';
import '../models/book.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/paypal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:7114/api',
  );

  static String _authHeader = '';
  static int userID = 0;

  static String? roleName;
  static bool get isAdmin => (roleName?.toLowerCase().trim() == 'admin');

  static Future<void> _saveSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('userID', userID);
    await sp.setString('roleName', roleName ?? '');
    await sp.setString('_authHeader', _authHeader);
  }

  static Future<void> restoreSession() async {
    final sp = await SharedPreferences.getInstance();
    userID = sp.getInt('userID') ?? 0;
    roleName = sp.getString('roleName');
    _authHeader = sp.getString('_authHeader') ?? '';
  }

  static Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('userID');
    await sp.remove('roleName');
    await sp.remove('_authHeader');
    userID = 0;
    roleName = null;
    _authHeader = '';
  }

  static Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${_apiBase}/Users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Greška pri dodavanju uloge: ${response.body}');
    }
    final data = jsonDecode(response.body);
    userID = data["id"];
    roleName = (data["role"]?["name"] as String?)?.trim();
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    _authHeader = basicAuth;
  }

  static Future<List<Comment>> fetchComments() async {
    final response = await http.get(
      Uri.parse('${_apiBase}/Comment?RetrieveAll=true'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['items'];
      return data.map<Comment>((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri dohvatu komentara');
    }
  }

  static Future<void> addComment(String content) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Comment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': content, 'userId': userID}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Greška pri dodavanju komentara: ${response.body}');
    }
  }

  static Future<void> deleteComment(int id) async {
    final response = await http.delete(Uri.parse('${_apiBase}/Comment/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Greška pri brisanju komentara");
    }
  }

  static Future<List<CommentAnswer>> fetchCommentAnswers() async {
    final response = await http.get(Uri.parse('${_apiBase}/CommentAnswer'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['items'];
      return data
          .map<CommentAnswer>((json) => CommentAnswer.fromJson(json))
          .toList();
    } else {
      throw Exception('Greška pri dohvatu odgovora');
    }
  }

  static Future<void> addCommentAnswer(
    int parentCommentId,
    String content,
    int userId, {
    int? replyToCommentId,
  }) async {
    final body = {
      'content': content,
      'userId': userId,
      'parentCommentId': parentCommentId,
    };

    if (replyToCommentId != null) {
      body['replyToCommentId'] = replyToCommentId;
    }

    final response = await http.post(
      Uri.parse('$_apiBase/CommentAnswer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Greška pri dodavanju odgovora: ${response.body}');
    }
  }

  static Future<void> deleteCommentAnswer(int id) async {
    final response = await http.delete(
      Uri.parse('${_apiBase}/CommentAnswer/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception("Greška pri brisanju odgovora");
    }
  }

  static Future<void> addCommentReaction({
    required int userId,
    int? commentId,
    int? commentAnswerId,
    required bool isLike,
  }) async {
    final Map<String, dynamic> body = {
      'userId': userId,
      'isLike': isLike,
      if (commentId != null) 'commentId': commentId,
      if (commentAnswerId != null) 'commentAnswerId': commentAnswerId,
    };

    final resp = await http.post(
      Uri.parse('$_apiBase/CommentReaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Greška pri reakciji: ${resp.body}');
    }
  }

  static Future<void> deleteCommentReaction({
    required int userId,
    int? commentId,
    int? commentAnswerId,
  }) async {
    final Map<String, dynamic> body = {
      'userId': userId,
      if (commentId != null) 'commentId': commentId,
      if (commentAnswerId != null) 'commentAnswerId': commentAnswerId,
    };

    final resp = await http.delete(
      Uri.parse('$_apiBase/CommentReaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Greška pri brisanju reakcije: ${resp.body}');
    }
  }

  static Future<Map<String, dynamic>?> fetchMyReactions(int userId) async {
    final resp = await http.get(
      Uri.parse('$_apiBase/CommentReaction?UserId=$userId'),
    );

    if (resp.statusCode != 200) {
      throw Exception('Greška pri dohvatu mojih reakcija: ${resp.body}');
    }

    if (resp.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    final List<Map<String, dynamic>> items =
        (data['items'] as List? ?? []).cast<Map<String, dynamic>>();

    return {
      'items': items,
    };
  }

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('${_apiBase}/Category'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri dohvatanju kategorija');
    }
  }

  static Future<List<Book>> fetchBooks({int? categoryId}) async {
    final uri = Uri.parse('${_apiBase}/Book').replace(
      queryParameters:
          categoryId != null ? {'CategoryId': categoryId.toString()} : null,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri dohvatu knjiga');
    }
  }

  static Future<List<Book>> fetchRecommendedBooks({int? categoryId}) async {
    final queryParams = <String, String>{
      'userId': userID.toString(),
    };
    if (categoryId != null) {
      queryParams['CategoryId'] = categoryId.toString();
    }

    final uri = Uri.parse('${_apiBase}/Book/recommended')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri dohvatu preporučenih knjiga');
    }
  }

  static Future<List<Book>> fetchNewBooks() async {
    final response = await http.get(Uri.parse('${_apiBase}/Book/new'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Greška pri dohvatu knjiga');
    }
  }

  static Future<List<Book>> fetchUserBooks() async {
    final url = Uri.parse('$_apiBase/Users/$userID');
    final resp = await http.get(url);

    if (resp.statusCode != 200) {
      throw Exception('Greška pri dohvatu korisničkih knjiga: ${resp.body}');
    }

    final decoded = json.decode(resp.body);
    if (decoded is Map<String, dynamic>) {
      final userBooks = decoded['userBooks'];
      if (userBooks is List) {
        return userBooks
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Polje "userBooks" nije lista: ${userBooks.runtimeType}',
        );
      }
    }

    throw Exception('Neočekivan format odgovora: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> fetchUserById() async {
    final resp = await http.get(Uri.parse('$_apiBase/Users/${userID}'));
    if (resp.statusCode != 200) {
      throw Exception('Greška pri dohvatu korisnika: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<void> updateUser({
    required String firstName,
    required String lastName,
    required String email,
    String? password,
  }) async {
    final current = await fetchUserById();

    final int? roleId =
        (current['roleId'] as int?) ?? (current['role']?['id'] as int?);
    final int? cityId =
        (current['cityId'] as int?) ?? (current['city']?['id'] as int?);

    final body = {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "username": current["username"] ?? "",
      "phoneNumber": current["phoneNumber"] ?? "",
      "birthDate": current["birthDate"],
      "gender": current["gender"],
      if (roleId != null) "roleId": roleId,
      if (cityId != null) "cityId": cityId,
    };

    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }

    final resp = await http.put(
      Uri.parse('$_apiBase/Users/${userID}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Greška pri izmjeni korisnika: ${resp.body}');
    }
  }

  static Future<int> createOrder({
    required int type,
    required List<Map<String, dynamic>> orderItems,
    required double totalPrice,
    required int paymentStatus,
  }) async {
    final body = {
      "orderDate": DateTime.now().toIso8601String(),
      "totalPrice": totalPrice,
      "orderStatus": 0,
      "paymentStatus": paymentStatus,
      "type": type,
      "userId": userID,
      "orderItems": orderItems,
    };

    final response = await http.post(
      Uri.parse('$_apiBase/Order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Greška pri kreiranju narudžbe: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['id']; // 👈 KLJUČNO
  }

  static Future<List<OrderResponse>> fetchOrders({int? type}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type.toString();

    final uri = Uri.parse('$_apiBase/Order').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('Greška pri dohvatu narudžbi: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List items = (decoded['items'] as List?) ?? [];

    return items.map((e) => OrderResponse.fromJson(e)).toList();
  }

  static Future<void> createReview({
    required double rating,
    required int bookId
  }) async {
    final body = {
      "rating": rating,
      "bookId": bookId,
      "userId": userID,
    };

    final response = await http.post(
      Uri.parse('$_apiBase/Review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Greška pri kreiranju recenzije: ${response.body}',
      );
    }
  }

  static Future<UserReviewResult?> fetchUserReview({
    required int bookId,
  }) async {
    final url = '$_apiBase/Review?BookId=$bookId&UserId=$userID';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': _authHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('Greška pri dohvaćanju recenzije: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['items'] == null || data['items'].isEmpty) {
      return null;
    }

    final item = data['items'][0];
    return UserReviewResult(
      item['id'],
      (item['rating'] as num).toDouble(),
    );
  }

  static Future<void> updateReview({
    required int reviewId,
    required double rating,
    required int bookId,
  }) async {
    final body = {
      "rating": rating,
      "bookId": bookId,
      "userId": userID,
    };

    final response = await http.put(
      Uri.parse('$_apiBase/Review/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Greška pri izmjeni recenzije: ${response.body}');
    }
  }

  static Future<void> reportComment({
    required int? userReportedId,
    required String? reason,
  }) async {
    final body = {
      'reason': reason,
      'userReportedId': userReportedId,
      'reportedByUserId': userID,
    };

    final resp = await http.post(
      Uri.parse('$_apiBase/UserReport'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Greška pri prijavi komentara: ${resp.body}');
    }
  }

  // OVO stavi kako ti odgovara - poenta je da prefix bude isti kao backend Return/Cancel URL
  static String get paypalReturnUrlPrefix => 'eknjiga://paypal-return';
  static String get paypalCancelUrlPrefix => 'eknjiga://paypal-cancel';

  static Future<PaypalCreateOrderResult> paypalCreateOrder({
    required int orderId,
    required double amount,
    String currency = 'EUR',
  }) async {
    final body = {
      "orderId": orderId,
      "amount": amount,
      "currency": currency,
    };

    final response = await http.post(
      Uri.parse('$_apiBase/Paypal/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('PayPal create-order greška: ${response.body}');
    }

    return PaypalCreateOrderResult.fromJson(jsonDecode(response.body));
  }

  static Future<void> paypalCaptureOrder(String paypalOrderId) async {
    final response = await http.post(
      Uri.parse('$_apiBase/Paypal/capture-order/$paypalOrderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('PayPal capture-order greška: ${response.body}');
    }
  }

}
