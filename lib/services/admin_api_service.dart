import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class AdminApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (ApiService.accessToken != null) 'Authorization': 'Bearer ${ApiService.accessToken}',
  };
  static Map<String, String> get _authOnly => {
    if (ApiService.accessToken != null) 'Authorization': 'Bearer ${ApiService.accessToken}',
  };

  static Future<Map<String, dynamic>> _handle(http.Response r) async {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (!(body['success'] as bool? ?? false)) {
      throw ApiException(body['message'] ?? 'Error', statusCode: r.statusCode);
    }
    return body;
  }

  // ── Auth ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password, {int? locationId}) async {
    final r = await http.post(
      Uri.parse('${AppConfig.baseUrl}/admin/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, if (locationId != null) 'location_id': locationId}),
    );
    final body = await _handle(r);
    await ApiService.saveTokens(body['data']['token'], body['data']['token']);
    return body['data'];
  }

  // ── Locations ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLocations() async {
    final r = await http.get(Uri.parse('${AppConfig.baseUrl}/locations'), headers: {'Content-Type': 'application/json'});
    final body = await _handle(r);
    return List<Map<String, dynamic>>.from(body['data'] as List);
  }

  // ── Dashboard ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    final r = await http.get(Uri.parse('${AppConfig.baseUrl}/admin/dashboard'), headers: _headers);
    return (await _handle(r))['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getReports({String period = 'daily'}) async {
    final r = await http.get(Uri.parse('${AppConfig.baseUrl}/admin/dashboard/reports?period=$period'), headers: _headers);
    return (await _handle(r))['data'] as List;
  }

  // ── Orders ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getOrders({String? status, int? locationId, int page = 1}) async {
    var url = '${AppConfig.baseUrl}/admin/orders?page=$page&limit=20';
    if (status != null) url += '&status=$status';
    if (locationId != null) url += '&location_id=$locationId';
    final r = await http.get(Uri.parse(url), headers: _headers);
    final b = await _handle(r);
    return {'orders': b['data'], 'pagination': b['pagination']};
  }

  static Future<void> updateOrderStatus(int id, String status, {String? note}) async {
    final r = await http.put(
      Uri.parse('${AppConfig.baseUrl}/admin/orders/$id/status'), headers: _headers,
      body: jsonEncode({'status': status, if (note != null) 'note': note}),
    );
    await _handle(r);
  }

  static Future<Map<String, dynamic>> getInvoice(int id) async {
    final r = await http.get(Uri.parse('${AppConfig.baseUrl}/admin/orders/$id/invoice'), headers: _headers);
    return (await _handle(r))['data'] as Map<String, dynamic>;
  }

  // ── Users ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUsers({String? search, bool? isBlocked, int page = 1}) async {
    var url = '${AppConfig.baseUrl}/admin/users?page=$page&limit=20';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    if (isBlocked != null) url += '&is_blocked=$isBlocked';
    final r = await http.get(Uri.parse(url), headers: _headers);
    final b = await _handle(r);
    return {'users': b['data'], 'pagination': b['pagination']};
  }

  static Future<void> blockUser(int id, bool block) async {
    final r = await http.put(Uri.parse('${AppConfig.baseUrl}/admin/users/$id/block'),
      headers: _headers, body: jsonEncode({'is_blocked': block}));
    await _handle(r);
  }

  // ── Menu ───────────────────────────────────────────────────────
  /// Admin-specific product list — returns ALL products including globally unavailable
  static Future<List<Product>> getAdminProducts({bool showUnavailable = true, String? search, int? categoryId}) async {
    var url = '${AppConfig.baseUrl}/admin/menu/products?limit=200';
    if (showUnavailable) url += '&show_unavailable=true';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    if (categoryId != null) url += '&category_id=$categoryId';
    final r = await http.get(Uri.parse(url), headers: _headers);
    final b = await _handle(r);
    return (b['data'] as List).map((p) => Product.fromJson(p)).toList();
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('${AppConfig.baseUrl}/admin/menu/products'),
      headers: _headers, body: jsonEncode(data));
    return (await _handle(r))['data'] as Map<String, dynamic>;
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$id'),
      headers: _headers, body: jsonEncode(data));
    await _handle(r);
  }

  static Future<void> deleteProduct(int id) async {
    final r = await http.delete(Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$id'), headers: _headers);
    await _handle(r);
  }

  static Future<String> uploadProductImage(int productId, File imageFile) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$productId/image');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authOnly)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    return ((await _handle(resp))['data'] as Map<String, dynamic>)['image_url'] as String;
  }

  /// Toggle availability for the admin's own location
  static Future<void> setProductLocationAvailability(int productId, bool isAvailable) async {
    final r = await http.put(
      Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$productId/location-availability'),
      headers: _headers, body: jsonEncode({'is_available': isAvailable}),
    );
    await _handle(r);
  }

  /// Super admin: toggle for any location by id
  static Future<void> setProductLocationAvailabilityForLocation(int productId, int locationId, bool isAvailable) async {
    final r = await http.put(
      Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$productId/location-availability'),
      headers: _headers, body: jsonEncode({'is_available': isAvailable, 'location_id': locationId}),
    );
    await _handle(r);
  }

  /// Get the availability matrix for a product across all locations
  static Future<List<Map<String, dynamic>>> getProductAvailabilityMatrix(int productId) async {
    final r = await http.get(
      Uri.parse('${AppConfig.baseUrl}/admin/menu/products/$productId/availability-matrix'),
      headers: _headers,
    );
    final b = await _handle(r);
    return List<Map<String, dynamic>>.from(b['data'] as List);
  }

  // ── Coupons ────────────────────────────────────────────────────
  static Future<void> createCoupon(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('${AppConfig.baseUrl}/admin/coupons'),
      headers: _headers, body: jsonEncode(data));
    await _handle(r);
  }

  // ── Refunds ────────────────────────────────────────────────────
  static Future<List<dynamic>> getRefunds({String? status}) async {
    var url = '${AppConfig.baseUrl}/admin/refunds';
    if (status != null) url += '?status=$status';
    return ((await _handle(await http.get(Uri.parse(url), headers: _headers)))['data'] as List);
  }

  static Future<void> processRefund(int id, String action, {String? notes}) async {
    final r = await http.post(Uri.parse('${AppConfig.baseUrl}/admin/refunds/$id/process'),
      headers: _headers, body: jsonEncode({'action': action, if (notes != null) 'notes': notes}));
    await _handle(r);
  }

  // ── Support ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTickets({String? status, int page = 1}) async {
    var url = '${AppConfig.baseUrl}/admin/support/tickets?page=$page';
    if (status != null) url += '&status=$status';
    final r = await http.get(Uri.parse(url), headers: _headers);
    final b = await _handle(r);
    return {'tickets': b['data'], 'pagination': b['pagination']};
  }

  static Future<void> replyTicket(int id, String message, {String? status}) async {
    final r = await http.post(Uri.parse('${AppConfig.baseUrl}/admin/support/tickets/$id/reply'),
      headers: _headers, body: jsonEncode({'message': message, if (status != null) 'status': status}));
    await _handle(r);
  }
}
