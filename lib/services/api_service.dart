import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

// Simple logger to avoid adding too many lines
void _log(String message, {bool isError = false}) {
  // ignore: avoid_print
  print('${isError ? '❌ ERROR' : '📱 API'}: $message');
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String? _accessToken;
  static String? _refreshToken;

  static Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    _log('Init - Logged in: ${_accessToken != null}');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    _log('Tokens saved');
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
    _log('Tokens cleared');
  }

  static bool get isLoggedIn => _accessToken != null;
  static String? get accessToken => _accessToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    _log('Response ${response.statusCode}: ${response.request?.url.path}');

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 401 && _refreshToken != null) {
      _log('Token expired, attempting refresh');
      final refreshed = await _tryRefresh();
      if (refreshed) throw ApiException('token_refreshed');
    }

    if (!(body['success'] ?? false)) {
      _log(body['message'] ?? 'Error', isError: true);
      throw ApiException(body['message'] ?? 'An error occurred', statusCode: response.statusCode);
    }
    return body;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppStrings.refreshToken}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        await saveTokens(body['data']['accessToken'], body['data']['refreshToken']);
        _log('Token refresh successful');
        return true;
      }
    } catch (e) {
      _log('Refresh failed: $e', isError: true);
    }
    await clearTokens();
    return false;
  }

  // ─── AUTH ─────────────────────────────────────────────────────────

  static Future<void> sendOtp(String email) async {
    _log('sendOtp: $email');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.sendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    await _handleResponse(response);
  }

  static Future<void> resendOtp(String email) async {
    _log('resendOtp: $email');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.resendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    await _handleResponse(response);
  }

  static Future<AuthResponse> register(String name, String email, String otp, {String? mobile}) async {
    _log('register: $email');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'otp': otp, if (mobile != null) 'mobile': mobile}),
    );
    final body = await _handleResponse(response);
    final auth = AuthResponse.fromJson(body['data']);
    await saveTokens(auth.accessToken, auth.refreshToken);
    return auth;
  }

  static Future<AuthResponse> login(String email, String otp) async {
    _log('login: $email');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final body = await _handleResponse(response);
    final auth = AuthResponse.fromJson(body['data']);
    await saveTokens(auth.accessToken, auth.refreshToken);
    return auth;
  }

  static Future<void> logout() async {
    _log('logout');
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppStrings.logout}'),
        headers: _headers,
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
    } catch (_) {}
    await clearTokens();
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    _log('updateProfile');
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.updateProfile}'),
      headers: _headers,
      body: jsonEncode(data),
    );
    await _handleResponse(response);
  }

  // ─── LOCATIONS ─────────────────────────────────────────────────────

  static Future<List<Location>> getLocations({double? lat, double? lng}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.locations}';
    if (lat != null && lng != null) url += '?latitude=$lat&longitude=$lng';

    _log('getLocations: $url');

    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      _log('Locations response: ${response.statusCode}');

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && (body['success'] == true || body['success'] == null)) {
        if (body['data'] != null) {
          final locations = (body['data'] as List).map((l) => Location.fromJson(l)).toList();
          _log('Loaded ${locations.length} locations');
          return locations;
        }
      }
      throw ApiException(body['message'] ?? 'Failed to load locations');
    } catch (e) {
      _log('getLocations error: $e', isError: true);
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  static Future<Location?> getNearestLocation({double? lat, double? lng}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.nearestLocation}';
    if (lat != null && lng != null) url += '?latitude=$lat&longitude=$lng';
    _log('getNearestLocation: $url');

    final response = await http.get(Uri.parse(url), headers: _headers);
    final body = await _handleResponse(response);
    if (body['data'] == null) return null;
    return Location.fromJson(body['data']);
  }

  // ─── MENU ──────────────────────────────────────────────────────────

  static Future<List<Category>> getCategories() async {
    _log('getCategories');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.categories}'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return (body['data'] as List).map((c) => Category.fromJson(c)).toList();
  }

  static Future<Map<String, dynamic>> getProducts({
    int? categoryId, bool? isVeg, String? search, int page = 1, int limit = 20,
    int? locationId,
  }) async {
    var params = 'page=$page&limit=$limit';
    if (categoryId != null) params += '&category_id=$categoryId';
    if (isVeg != null) params += '&is_veg=$isVeg';
    if (search != null && search.isNotEmpty) params += '&search=${Uri.encodeComponent(search)}';
    if (locationId != null) params += '&location_id=$locationId';

    _log('getProducts: $params');

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.products}?$params'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return {
      'products': (body['data'] as List).map((p) => Product.fromJson(p)).toList(),
      'pagination': body['pagination'],
    };
  }

  static Future<List<Product>> getFeaturedProducts({int? locationId}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.featuredProducts}';
    if (locationId != null) url += '?location_id=$locationId';
    _log('getFeaturedProducts');

    final response = await http.get(Uri.parse(url), headers: _headers);
    final body = await _handleResponse(response);
    return (body['data'] as List).map((p) => Product.fromJson(p)).toList();
  }

  static Future<Product> getProduct(int id) async {
    _log('getProduct: $id');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.products}/$id'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return Product.fromJson(body['data']);
  }

  static Future<List<Topping>> getToppings({bool? isVeg}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.toppings}';
    if (isVeg != null) url += '?is_veg=$isVeg';
    _log('getToppings');

    final response = await http.get(Uri.parse(url), headers: _headers);
    final body = await _handleResponse(response);
    return (body['data'] as List).map((t) => Topping.fromJson(t)).toList();
  }

  static Future<List<CrustType>> getCrusts() async {
    _log('getCrusts');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.crusts}'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return (body['data'] as List).map((c) => CrustType.fromJson(c)).toList();
  }

  // ─── ORDERS ─────────────────────────────────────────────────────────

  static Future<OrderCalculation> calculateOrder(
      List<Map<String, dynamic>> items, {String? couponCode, String deliveryType = 'delivery'}
      ) async {
    _log('calculateOrder');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.calculateOrder}'),
      headers: _headers,
      body: jsonEncode({'items': items, if (couponCode != null) 'coupon_code': couponCode, 'delivery_type': deliveryType}),
    );
    final body = await _handleResponse(response);
    return OrderCalculation.fromJson(body['data']);
  }

  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    _log('placeOrder');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.orders}'),
      headers: _headers,
      body: jsonEncode(orderData),
    );
    final body = await _handleResponse(response);
    return body['data'];
  }

  static Future<Map<String, dynamic>> getOrders({String? status, int page = 1}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.orders}?page=$page';
    if (status != null) url += '&status=$status';
    _log('getOrders: $url');

    final response = await http.get(Uri.parse(url), headers: _headers);
    final body = await _handleResponse(response);
    return {
      'orders': (body['data'] as List).map((o) => Order.fromJson(o)).toList(),
      'pagination': body['pagination'],
    };
  }

  static Future<Order> getOrder(int id) async {
    _log('getOrder: $id');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.orders}/$id'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return Order.fromJson(body['data']);
  }

  static Future<void> cancelOrder(int id, {String? reason}) async {
    _log('cancelOrder: $id');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.orders}/$id/cancel'),
      headers: _headers,
      body: jsonEncode({'reason': reason ?? 'Cancelled by user'}),
    );
    await _handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> reorder(int id) async {
    _log('reorder: $id');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.orders}/$id/reorder'),
      headers: _headers,
      body: jsonEncode({}),
    );
    final body = await _handleResponse(response);
    return List<Map<String, dynamic>>.from(body['data']['items']);
  }

  // ─── COUPONS ────────────────────────────────────────────────────────

  static Future<List<Coupon>> getCoupons() async {
    _log('getCoupons');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.coupons}'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return (body['data'] as List).map((c) => Coupon.fromJson(c)).toList();
  }

  static Future<Coupon> validateCoupon(String code, double orderValue) async {
    _log('validateCoupon: $code');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.validateCoupon}'),
      headers: _headers,
      body: jsonEncode({'code': code, 'order_value': orderValue}),
    );
    final body = await _handleResponse(response);
    return Coupon.fromJson(body['data']);
  }

  // ─── PAYMENTS ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createPaymentOrder(int orderId, String paymentMethod) async {
    _log('createPaymentOrder: $orderId');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.createPayment}'),
      headers: _headers,
      body: jsonEncode({'order_id': orderId, 'payment_method': paymentMethod}),
    );
    final body = await _handleResponse(response);
    return body['data'];
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications() async {
    _log('getNotifications');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.notifications}'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return {
      'notifications': (body['data']['notifications'] as List)
          .map((n) => AppNotification.fromJson(n)).toList(),
      'unread_count': body['data']['unread_count'],
    };
  }

  static Future<void> markAllNotificationsRead() async {
    _log('markAllNotificationsRead');
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.markAllRead}'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  static Future<void> markNotificationRead(int id) async {
    _log('markNotificationRead: $id');
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.notifications}/$id/read'),
      headers: _headers,
    );
    await _handleResponse(response);
  }

  // ─── SUPPORT ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    _log('createTicket');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.supportTickets}'),
      headers: _headers,
      body: jsonEncode(data),
    );
    final body = await _handleResponse(response);
    return body['data'];
  }

  static Future<List<SupportTicket>> getTickets({String? status}) async {
    var url = '${AppConfig.baseUrl}${AppStrings.supportTickets}';
    if (status != null) url += '?status=$status';
    _log('getTickets');

    final response = await http.get(Uri.parse(url), headers: _headers);
    final body = await _handleResponse(response);
    return (body['data'] as List).map((t) => SupportTicket.fromJson(t)).toList();
  }

  static Future<SupportTicket> getTicket(int id) async {
    _log('getTicket: $id');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.supportTickets}/$id'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return SupportTicket.fromJson(body['data']);
  }

  static Future<void> replyToTicket(int id, String message) async {
    _log('replyToTicket: $id');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.supportTickets}/$id/reply'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    await _handleResponse(response);
  }

  // ─── REFUNDS ──────────────────────────────────────────────────────────

  static Future<void> requestRefund(int orderId, String reason) async {
    _log('requestRefund: $orderId');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.refundRequest}'),
      headers: _headers,
      body: jsonEncode({'order_id': orderId, 'reason': reason}),
    );
    await _handleResponse(response);
  }

  static Future<List<dynamic>> getMyRefunds() async {
    _log('getMyRefunds');
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.myRefunds}'),
      headers: _headers,
    );
    final body = await _handleResponse(response);
    return body['data'];
  }

  // ─── RATINGS ──────────────────────────────────────────────────────────

  static Future<void> submitRating(int orderId, int productId, int rating, {String? review}) async {
    _log('submitRating: $productId');
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppStrings.ratings}'),
      headers: _headers,
      body: jsonEncode({'order_id': orderId, 'product_id': productId, 'rating': rating, if (review != null) 'review': review}),
    );
    await _handleResponse(response);
  }
}