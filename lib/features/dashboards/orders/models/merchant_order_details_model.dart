class MerchantOrderDetails {
  final OrderInfo info;
  final List<MerchantOrderItem> items;

  MerchantOrderDetails({required this.info, required this.items});

  factory MerchantOrderDetails.fromJson(Map<String, dynamic> json) {
    return MerchantOrderDetails(
      info: OrderInfo.fromJson(json['details'] ?? {}),
      items: (json['items'] as List?)
              ?.map((item) => MerchantOrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderInfo {
  final int id;
  final String status;
  final DateTime createdAt;
  final double totalAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? shippingAddress;

  OrderInfo({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'] ?? 'unknown',
      customerName: json['customerName'] ?? 'Unknown',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'],
      shippingAddress: json['shippingAddress'],
    );
  }
}

class MerchantOrderItem {
  final int productId;
  final String name;
  final int quantity;
  final double price;
  final String? image;

  MerchantOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
  });

  factory MerchantOrderItem.fromJson(Map<String, dynamic> json) {
    // معالجة الصورة لأنها قد تأتي كنص JSON أحياناً
    String? imgUrl = json['image'];
    if (imgUrl != null && imgUrl.startsWith('"')) {
      imgUrl = imgUrl.replaceAll('"', '');
    }

    return MerchantOrderItem(
      productId: json['productId'] is int ? json['productId'] : int.tryParse(json['productId'].toString()) ?? 0,
      name: json['name'] ?? 'منتج',
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: imgUrl,
    );
  }
}