class SupplierOrder {
  final int orderId;
  final String orderDate;
  final String orderStatus;
  final String productName;
  final int quantity;
  final double costPrice;
  final String customerName;
  final String merchantStoreName;
  final double totalCost;

  SupplierOrder({
    required this.orderId,
    required this.orderDate,
    required this.orderStatus,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.customerName,
    required this.merchantStoreName,
    required this.totalCost,
  });

  factory SupplierOrder.fromJson(Map<String, dynamic> json) {
    return SupplierOrder(
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      orderDate: json['order_date'] ?? '',
      orderStatus: json['order_status'] ?? 'pending',
      productName: json['product_name'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      customerName: json['customer_name'] ?? '',
      merchantStoreName: json['merchant_store_name'] ?? '',
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0.0,
    );
  }
}

// تفاصيل الطلب الكاملة (للنافذة المنبثقة)
class OrderDetails {
  final int orderId;
  final String orderDate;
  final String orderStatus;
  final double shippingCost;
  final double totalAmount;
  final String paymentMethod;
  final CustomerInfo customer;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;

  OrderDetails({
    required this.orderId,
    required this.orderDate,
    required this.orderStatus,
    required this.shippingCost,
    required this.totalAmount,
    required this.paymentMethod,
    required this.customer,
    required this.shippingAddress,
    required this.items,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      orderDate: json['order_date'] ?? '',
      orderStatus: json['order_status'] ?? 'pending',
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'N/A',
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      shippingAddress: ShippingAddress.fromJson(json['shipping_address'] ?? {}),
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
    );
  }
}

class CustomerInfo {
  final String name;
  final String email;
  CustomerInfo({required this.name, required this.email});
  factory CustomerInfo.fromJson(Map<String, dynamic> json) => 
      CustomerInfo(name: json['name'] ?? '', email: json['email'] ?? '');
}

class ShippingAddress {
  final String name;
  final String address;
  final String city;
  final String country;
  final String phone;
  ShippingAddress({required this.name, required this.address, required this.city, required this.country, required this.phone});
  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
    name: json['name'] ?? '', address: json['address'] ?? '',
    city: json['city'] ?? '', country: json['country'] ?? '', phone: json['phone'] ?? ''
  );
}

class OrderItem {
  final String name;
  final String color;
  final int quantity;
  final double totalCost;
  OrderItem({required this.name, required this.color, required this.quantity, required this.totalCost});
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] ?? '', color: json['color'] ?? '',
    quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    totalCost: double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0.0,
  );
}