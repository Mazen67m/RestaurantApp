import 'menu_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
  rejected,
}

enum OrderType {
  delivery,
  pickup,
}

class Order {
  final int id;
  final String orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final double subTotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final int? branchId;
  final int? deliveryAddressId;
  final String? paymentMethod;
  final String? deliveryAddressLine;
  final String? customerNotes;
  final DateTime? requestedDeliveryTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;
  final BranchInfo branch;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.subTotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.branchId,
    this.deliveryAddressId,
    this.paymentMethod,
    this.deliveryAddressLine,
    this.customerNotes,
    this.requestedDeliveryTime,
    this.estimatedDeliveryTime,
    required this.createdAt,
    required this.branch,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['orderNumber'],
      orderType: OrderType.values[json['orderType']],
      status: OrderStatus.values[json['status']],
      subTotal: (json['subTotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      branchId: json['branchId'],
      deliveryAddressId: json['deliveryAddressId'],
      paymentMethod: json['paymentMethod'],
      deliveryAddressLine: json['deliveryAddressLine'],
      customerNotes: json['customerNotes'],
      requestedDeliveryTime: json['requestedDeliveryTime'] != null
          ? DateTime.parse(json['requestedDeliveryTime'])
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      branch: BranchInfo.fromJson(json['branch']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}

class BranchInfo {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? phone;

  BranchInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.phone,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'],
      nameAr: json['nameAr'],
      nameEn: json['nameEn'],
      phone: json['phone'],
    );
  }

  String getName(bool isArabic) => isArabic ? nameAr : nameEn;
}

class OrderItem {
  final int id;
  final int menuItemId;
  final String menuItemNameAr;
  final String menuItemNameEn;
  final double unitPrice;
  final int quantity;
  final double addOnsTotal;
  final double totalPrice;
  final String? notes;
  final List<OrderItemAddOn> addOns;

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemNameAr,
    required this.menuItemNameEn,
    required this.unitPrice,
    required this.quantity,
    required this.addOnsTotal,
    required this.totalPrice,
    this.notes,
    this.addOns = const [],
  });

  // Alias for notes
  String? get specialInstructions => notes;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      menuItemId: json['menuItemId'],
      menuItemNameAr: json['menuItemNameAr'],
      menuItemNameEn: json['menuItemNameEn'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'],
      addOnsTotal: (json['addOnsTotal'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      notes: json['notes'],
      addOns: json['addOns'] != null
          ? (json['addOns'] as List)
              .map((a) => OrderItemAddOn.fromJson(a))
              .toList()
          : [],
    );
  }

  String getName(bool isArabic) => isArabic ? menuItemNameAr : menuItemNameEn;
}

class OrderItemAddOn {
  final int id;
  final String nameAr;
  final String nameEn;
  final double price;

  OrderItemAddOn({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
  });

  factory OrderItemAddOn.fromJson(Map<String, dynamic> json) {
    return OrderItemAddOn(
      id: json['id'],
      nameAr: json['nameAr'],
      nameEn: json['nameEn'],
      price: (json['price'] as num).toDouble(),
    );
  }

  String getName(bool isArabic) => isArabic ? nameAr : nameEn;
}

class OrderSummary {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final double total;
  final int itemCount;
  final DateTime createdAt;
  final String branchNameAr;
  final String branchNameEn;

  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.branchNameAr,
    required this.branchNameEn,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'],
      orderNumber: json['orderNumber'],
      status: OrderStatus.values[json['status']],
      total: (json['total'] as num).toDouble(),
      itemCount: json['itemCount'],
      createdAt: DateTime.parse(json['createdAt']),
      branchNameAr: json['branchNameAr'],
      branchNameEn: json['branchNameEn'],
    );
  }

  String getBranchName(bool isArabic) => isArabic ? branchNameAr : branchNameEn;
}

// Cart models
class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? notes;
  List<MenuItemAddOn> selectedAddOns;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.notes,
    this.selectedAddOns = const [],
  });

  double get addOnsTotal => 
      selectedAddOns.fold(0, (sum, addOn) => sum + addOn.price);
  
  double get itemTotal => 
      (menuItem.effectivePrice + addOnsTotal) * quantity;

  Map<String, dynamic> toOrderItemJson() {
    return {
      'menuItemId': menuItem.id,
      'quantity': quantity,
      'notes': notes,
      'addOnIds': selectedAddOns.map((a) => a.id).toList(),
    };
  }
}
