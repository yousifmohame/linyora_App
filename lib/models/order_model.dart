class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double totalPrice;
  final String date;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.date,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. تحديد مكان البيانات (هل هي مباشرة أم داخل 'details' كما في صفحة التفاصيل)
    final data = json['details'] != null ? json['details'] : json;
    
    // 2. معالجة المنتجات (Items)
    var itemsList = <OrderItemModel>[];
    
    // في صفحة التفاصيل، المنتجات تأتي في مفتاح 'items' بجانب 'details'
    if (json['items'] != null) {
      itemsList = (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList();
    } 
    // في صفحة القائمة (بعد تعديل الباك إند أعلاه)، وضعنا صورة وهمية داخل items
    else if (data['items'] != null) {
       itemsList = (data['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList();
    }

    // 3. قراءة الحقول مع مراعاة اختلاف التسميات (camelCase vs snake_case)
    return OrderModel(
      id: data['id'],
      orderNumber: '#${data['id']}',
      status: data['status'] ?? 'pending',
      // الباك إند يرسل totalAmount في التفاصيل و totalPrice في القائمة (بعد تعديلنا)
      totalPrice: double.tryParse((data['totalPrice'] ?? data['totalAmount'] ?? 0).toString()) ?? 0.0,
      // الباك إند يرسل created_at في التفاصيل و date في القائمة
      date: data['date'] ?? data['created_at'] ?? '',
      items: itemsList,
    );
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // معالجة الصور القادمة من الباك إند
    String image = '';
    
    // الحالة 1: في صفحة التفاصيل، الصور تأتي مصفوفة ['url1', 'url2']
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      image = json['images'][0]; 
    } 
    // الحالة 2: في القائمة (بعد تعديل الباك إند)، أرسلناها باسم productImage
    else if (json['productImage'] != null) {
      image = json['productImage'];
    }

    return OrderItemModel(
      id: json['product_id'] ?? 0, // الباك إند يرسل product_id
      productName: json['productName'] ?? '',
      productImage: image,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}