import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import '../services/api_service.dart';

// ─── AUTH PROVIDER ───────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && ApiService.isLoggedIn;

  Future<void> init() async {
    await ApiService.init();
    if (ApiService.isLoggedIn) {
      try {
        notifyListeners();
      } catch (_) {
        await ApiService.clearTokens();
      }
    }
  }

  Future<bool> sendOtp(String email) async {
    _loading = true; _error = null; notifyListeners();
    try {
      await ApiService.sendOtp(email);
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      await ApiService.resendOtp(email);
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    }
  }

  Future<bool> login(String email, String otp) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final auth = await ApiService.login(email, otp);
      _user = auth.user;
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String otp, {String? mobile}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final auth = await ApiService.register(name, email, otp, mobile: mobile);
      _user = auth.user;
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      await ApiService.updateProfile(data);
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ─── CART PROVIDER ───────────────────────────────────────────────

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _appliedCouponCode;
  Coupon? _appliedCoupon;
  int? _selectedLocationId;
  String? _selectedLocationName;
  String _deliveryType = 'delivery';
  String? _deliveryAddress;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get couponCode => _appliedCouponCode;
  Coupon? get appliedCoupon => _appliedCoupon;
  int? get selectedLocationId => _selectedLocationId;
  String? get selectedLocationName => _selectedLocationName;
  String get deliveryType => _deliveryType;
  String? get deliveryAddress => _deliveryAddress;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => _deliveryType == 'pickup' ? 0 : (subtotal < 300 ? 40 : 0);
  double get discount => _appliedCoupon?.calculatedDiscount ?? 0.0;
  double get tax => (subtotal - discount + deliveryFee) * 0.05;
  double get total => subtotal - discount + deliveryFee + tax;

  bool get isEmpty => _items.isEmpty;

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.uniqueKey == item.uniqueKey);
    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    notifyListeners();
  }

  void setLocation(int locationId, String locationName) {
    _selectedLocationId = locationId;
    _selectedLocationName = locationName;
    notifyListeners();
  }

  void setDeliveryType(String type) {
    _deliveryType = type;
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void applyCoupon(Coupon coupon) {
    _appliedCouponCode = coupon.code;
    _appliedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _appliedCoupon = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> toOrderItems() =>
    _items.map((i) => i.toOrderJson()).toList();

  void clear() {
    _items.clear();
    _appliedCouponCode = null;
    _appliedCoupon = null;
    notifyListeners();
  }
}

// ─── MENU PROVIDER ───────────────────────────────────────────────

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Product> _featuredProducts = [];
  List<Product> _products = [];
  List<Topping> _toppings = [];
  List<CrustType> _crusts = [];
  bool _loading = false;
  String? _error;
  int? _selectedCategoryId;
  int? _selectedLocationId;

  List<Category> get categories => _categories;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get products => _products;
  List<Topping> get toppings => _toppings;
  List<CrustType> get crusts => _crusts;
  bool get loading => _loading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedLocationId => _selectedLocationId;

  void setSelectedLocation(int locationId) {
    _selectedLocationId = locationId;
    notifyListeners();
  }

  Future<void> loadHomeData() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getFeaturedProducts(locationId: _selectedLocationId),
      ]);
      _categories = results[0] as List<Category>;
      _featuredProducts = results[1] as List<Product>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadProducts({int? categoryId, bool? isVeg, String? search}) async {
    _loading = true; _error = null;
    _selectedCategoryId = categoryId;
    notifyListeners();
    try {
      final result = await ApiService.getProducts(
        categoryId: categoryId, isVeg: isVeg, search: search,
        locationId: _selectedLocationId,
      );
      _products = result['products'] as List<Product>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadToppingsAndCrusts() async {
    try {
      final results = await Future.wait([ApiService.getToppings(), ApiService.getCrusts()]);
      _toppings = results[0] as List<Topping>;
      _crusts = results[1] as List<CrustType>;
      notifyListeners();
    } catch (_) {}
  }

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    loadProducts(categoryId: id);
  }
}

// ─── ORDER PROVIDER ───────────────────────────────────────────────

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _loading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders({String? status}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final result = await ApiService.getOrders(status: status);
      _orders = result['orders'] as List<Order>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadOrder(int id) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _currentOrder = await ApiService.getOrder(id);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> placeOrder(Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      return await ApiService.placeOrder(data);
    } on ApiException catch (e) {
      _error = e.message; return null;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> cancelOrder(int id, {String? reason}) async {
    try {
      await ApiService.cancelOrder(id, reason: reason);
      await loadOrder(id);
      return true;
    } on ApiException catch (e) {
      _error = e.message; return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ─── NOTIFICATION PROVIDER (DB-based, no FCM) ────────────────────

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true; notifyListeners();
    try {
      final result = await ApiService.getNotifications();
      _notifications = result['notifications'] as List<AppNotification>;
      _unreadCount = result['unread_count'] as int;
    } catch (_) {}
    _loading = false; notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
