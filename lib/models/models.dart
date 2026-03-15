// ─── AUTH MODELS ─────────────────────────────────────────────────

class User {
  final int id;
  final String name;
  final String email;
  final String? mobile;
  final String? profilePicture;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? preferredLocationId;
  final String? preferredLocationName;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.profilePicture,
    this.address,
    this.latitude,
    this.longitude,
    this.preferredLocationId,
    this.preferredLocationName,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    mobile: json['mobile'],
    profilePicture: json['profile_picture'],
    address: json['address'],
    latitude: _parseDoubleOrNull(json['latitude']),
    longitude: _parseDoubleOrNull(json['longitude']),
    preferredLocationId: json['preferred_location_id'],
    preferredLocationName: json['preferred_location_name'],
    createdAt: json['created_at'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'mobile': mobile, 'profile_picture': profilePicture,
    'address': address,
  };

  User copyWith({String? name, String? mobile, String? address, int? preferredLocationId}) => User(
    id: id, name: name ?? this.name, email: email,
    mobile: mobile ?? this.mobile,
    profilePicture: profilePicture, address: address ?? this.address,
    latitude: latitude, longitude: longitude,
    preferredLocationId: preferredLocationId ?? this.preferredLocationId,
    preferredLocationName: preferredLocationName, createdAt: createdAt,
  );
}

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: User.fromJson(json['user']),
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
  );
}

// ─── LOCATION MODEL ───────────────────────────────────────────────

class Location {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingTime;
  final String? closingTime;
  final double? distanceKm;

  Location({
    required this.id, required this.name, required this.address,
    required this.latitude, required this.longitude,
    this.phone, this.openingTime, this.closingTime, this.distanceKm,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'],
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    latitude: _parseDouble(json['latitude']),
    longitude: _parseDouble(json['longitude']),
    phone: json['phone'],
    openingTime: json['opening_time'],
    closingTime: json['closing_time'],
    distanceKm: _parseDoubleOrNull(json['distance_km']),
  );
}

// ─── MENU MODELS ──────────────────────────────────────────────────

class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;

  Category({required this.id, required this.name, this.description, this.imageUrl, required this.sortOrder});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'],
    imageUrl: json['image_url'],
    sortOrder: json['sort_order'] ?? 0,
  );
}

class ProductSize {
  final int id;
  final String sizeName;
  final double price;
  final bool isAvailable;

  ProductSize({required this.id, required this.sizeName, required this.price, required this.isAvailable});

  factory ProductSize.fromJson(Map<String, dynamic> json) => ProductSize(
    id: json['id'],
    sizeName: json['size_name'] ?? '',
    price: _parseDouble(json['price']),
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
  );
}

class CrustType {
  final int id;
  final String name;
  final double extraPrice;
  final bool isAvailable;

  CrustType({required this.id, required this.name, required this.extraPrice, required this.isAvailable});

  factory CrustType.fromJson(Map<String, dynamic> json) => CrustType(
    id: json['id'],
    name: json['name'] ?? '',
    extraPrice: _parseDouble(json['extra_price']),
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
  );
}

class Topping {
  final int id;
  final String name;
  final double price;
  final bool isVeg;
  final bool isAvailable;

  Topping({required this.id, required this.name, required this.price, required this.isVeg, required this.isAvailable});

  factory Topping.fromJson(Map<String, dynamic> json) => Topping(
    id: json['id'],
    name: json['name'] ?? '',
    price: _parseDouble(json['price']),
    isVeg: json['is_veg'] == 1 || json['is_veg'] == true,
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
  );
}

class Product {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double basePrice;
  final int categoryId;
  final String? categoryName;
  final bool isVeg;
  final bool isFeatured;
  final bool isAvailable;
  final double? avgRating;
  final int? reviewCount;
  final List<ProductSize> sizes;
  final List<CrustType> crusts;
  final List<Topping> toppings;
  // Per-location availability (null = globally available, set when admin fetches with location context)
  final bool? locationAvailable;

  Product({
    required this.id, required this.name, this.description, this.imageUrl,
    required this.basePrice, required this.categoryId, this.categoryName,
    required this.isVeg, required this.isFeatured, required this.isAvailable,
    this.avgRating, this.reviewCount,
    this.sizes = const [], this.crusts = const [], this.toppings = const [],
    this.locationAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'],
    imageUrl: json['image_url'],
    basePrice: _parseDouble(json['base_price']),
    categoryId: json['category_id'] ?? 0,
    categoryName: json['category_name'],
    isVeg: json['is_veg'] == 1 || json['is_veg'] == true,
    isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
    avgRating: json['avg_rating'] != null ? _parseDouble(json['avg_rating']) : null,
    reviewCount: json['review_count'],
    sizes: (json['sizes'] as List<dynamic>?)?.map((s) => ProductSize.fromJson(s)).toList() ?? [],
    crusts: (json['crusts'] as List<dynamic>?)?.map((c) => CrustType.fromJson(c)).toList() ?? [],
    toppings: (json['toppings'] as List<dynamic>?)?.map((t) => Topping.fromJson(t)).toList() ?? [],
    locationAvailable: json['location_available'] != null
      ? (json['location_available'] == 1 || json['location_available'] == true)
      : null,
  );
}

// ─── CART MODELS ──────────────────────────────────────────────────

class CartItem {
  final Product product;
  final ProductSize size;
  final CrustType? crust;
  final List<Topping> selectedToppings;
  int quantity;
  final String? specialInstructions;

  CartItem({
    required this.product, required this.size, this.crust,
    this.selectedToppings = const [], this.quantity = 1, this.specialInstructions,
  });

  double get unitPrice {
    double price = size.price;
    if (crust != null) price += crust!.extraPrice;
    for (final t in selectedToppings) {
      price += t.price;
    }
    return price;
  }

  double get totalPrice => unitPrice * quantity;

  String get uniqueKey =>
      '${product.id}-${size.id}-${crust?.id}-${selectedToppings.map((t) => t.id).join(',')}';

  Map<String, dynamic> toOrderJson() => {
    'product_id': product.id,
    'size_id': size.id,
    if (crust != null) 'crust_id': crust!.id,
    'toppings': selectedToppings.map((t) => t.id).toList(),
    'quantity': quantity,
    if (specialInstructions != null) 'special_instructions': specialInstructions,
  };
}

// ─── ORDER MODELS ─────────────────────────────────────────────────

class OrderCalculation {
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double taxAmount;
  final double totalAmount;

  OrderCalculation({
    required this.subtotal, required this.discountAmount,
    required this.deliveryFee, required this.taxAmount, required this.totalAmount,
  });

  factory OrderCalculation.fromJson(Map<String, dynamic> json) => OrderCalculation(
    subtotal: _parseDouble(json['subtotal']),
    discountAmount: _parseDouble(json['discount_amount']),
    deliveryFee: _parseDouble(json['delivery_fee']),
    taxAmount: _parseDouble(json['tax_amount']),
    totalAmount: _parseDouble(json['total_amount']),
  );
}

class OrderItem {
  final int id;
  final String productName;
  final String sizeName;
  final String? crustName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;
  final List<dynamic> toppings;

  OrderItem({
    required this.id, required this.productName, required this.sizeName,
    this.crustName, required this.quantity, required this.unitPrice,
    required this.totalPrice, this.imageUrl, this.toppings = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] ?? 0,
    productName: json['product_name'] ?? '',
    sizeName: json['size_name'] ?? '',
    crustName: json['crust_name'],
    quantity: json['quantity'] ?? 1,
    unitPrice: _parseDouble(json['unit_price']),
    totalPrice: _parseDouble(json['total_price']),
    imageUrl: json['image_url'],
    toppings: json['toppings'] ?? [],
  );
}

class OrderStatusHistory {
  final String status;
  final String? note;
  final String createdAt;

  OrderStatusHistory({required this.status, this.note, required this.createdAt});

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) => OrderStatusHistory(
    status: json['status'] ?? '',
    note: json['note'],
    createdAt: json['created_at'] ?? '',
  );
}

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String deliveryType;
  final String? deliveryAddress;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double taxAmount;
  final double totalAmount;
  final String? locationName;
  final String? specialInstructions;
  final String createdAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.id, required this.orderNumber, required this.status,
    required this.paymentStatus, required this.deliveryType, this.deliveryAddress,
    required this.subtotal, required this.discountAmount, required this.deliveryFee,
    required this.taxAmount, required this.totalAmount, this.locationName,
    this.specialInstructions, required this.createdAt,
    this.items = const [], this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? 0,
    orderNumber: json['order_number'] ?? '',
    status: json['status'] ?? '',
    paymentStatus: json['payment_status'] ?? '',
    deliveryType: json['delivery_type'] ?? 'delivery',
    deliveryAddress: json['delivery_address'],
    subtotal: _parseDouble(json['subtotal']),
    discountAmount: _parseDouble(json['discount_amount']),
    deliveryFee: _parseDouble(json['delivery_fee']),
    taxAmount: _parseDouble(json['tax_amount']),
    totalAmount: _parseDouble(json['total_amount']),
    locationName: json['location_name'],
    specialInstructions: json['special_instructions'],
    createdAt: json['created_at'] ?? '',
    items: (json['items'] as List<dynamic>?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
    statusHistory: (json['status_history'] as List<dynamic>?)?.map((s) => OrderStatusHistory.fromJson(s)).toList() ?? [],
  );

  bool get canCancel => status == 'pending' || status == 'confirmed';
}

// ─── COUPON MODEL ─────────────────────────────────────────────────

class Coupon {
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final String? validUntil;
  final double? calculatedDiscount;

  Coupon({
    required this.code, this.description, required this.discountType,
    required this.discountValue, required this.minOrderValue, this.validUntil, this.calculatedDiscount,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    code: json['code'] ?? '',
    description: json['description'],
    discountType: json['discount_type'] ?? 'flat',
    discountValue: _parseDouble(json['discount_value']),
    minOrderValue: _parseDouble(json['min_order_value']),
    validUntil: json['valid_until'],
    calculatedDiscount: json['calculated_discount'] != null ? _parseDouble(json['calculated_discount']) : null,
  );

  String get displayDiscount => discountType == 'percentage'
      ? '${discountValue.toInt()}% OFF'
      : '₹${discountValue.toInt()} OFF';
}

// ─── NOTIFICATION MODEL ───────────────────────────────────────────

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String? type;
  final String createdAt;

  AppNotification({
    required this.id, required this.title, required this.message,
    required this.isRead, this.type, required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    isRead: json['is_read'] == 1 || json['is_read'] == true,
    type: json['type'],
    createdAt: json['created_at'] ?? '',
  );
}

// ─── SUPPORT MODELS ───────────────────────────────────────────────

class SupportTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String status;
  final String? orderNumber;
  final String createdAt;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id, required this.ticketNumber, required this.subject,
    required this.category, required this.status, this.orderNumber,
    required this.createdAt, this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] ?? 0,
    ticketNumber: json['ticket_number'] ?? '',
    subject: json['subject'] ?? '',
    category: json['category'] ?? '',
    status: json['status'] ?? '',
    orderNumber: json['order_number'],
    createdAt: json['created_at'] ?? '',
    messages: (json['messages'] as List<dynamic>?)?.map((m) => SupportMessage.fromJson(m)).toList() ?? [],
  );
}

class SupportMessage {
  final int id;
  final String message;
  final String senderRole;
  final String? senderName;
  final String createdAt;

  SupportMessage({
    required this.id, required this.message, required this.senderRole,
    this.senderName, required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id'] ?? 0,
    message: json['message'] ?? '',
    senderRole: json['sender_role'] ?? 'user',
    senderName: json['sender_name'],
    createdAt: json['created_at'] ?? '',
  );
}

// ─── API RESPONSE ─────────────────────────────────────────────────

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? pagination;

  ApiResponse({required this.success, required this.message, this.data, this.pagination});
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Pagination({required this.total, required this.page, required this.limit, required this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json['total'] ?? 0,
    page: json['page'] ?? 1,
    limit: json['limit'] ?? 10,
    totalPages: json['totalPages'] ?? 1,
  );
}

// ─── HELPER FUNCTIONS ─────────────────────────────────────────────

// Helper function to safely parse double from various types
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Try to parse the string to double
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

// Helper function to safely parse nullable double from various types
double? _parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Try to parse the string to double
    return double.tryParse(value);
  }
  return null;
}