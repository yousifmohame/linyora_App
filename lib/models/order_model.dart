import 'dart:convert';
import 'package:flutter/foundation.dart';

class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double totalPrice;
  final String date;
  final double shippingCost;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.shippingCost,
    required this.date,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. التعامل مع اختلاف هيكلية الرد (سواء كانت البيانات مباشرة أو داخل 'details')
    final data = json['details'] != null ? json['details'] : json;

    // 2. معالجة قائمة المنتجات (Items) بحذر
    var itemsList = <OrderItemModel>[];
    var rawItems = json['items'] ?? data['items'];

    if (rawItems != null && rawItems is List) {
      itemsList = rawItems.map((i) => OrderItemModel.fromJson(i)).toList();
    }

    return OrderModel(
      id: data['id'] ?? 0,
      orderNumber: '#${data['id'] ?? '0'}',
      status: data['status'] ?? 'pending',
      totalPrice:
          double.tryParse(
            (data['totalPrice'] ?? data['totalAmount'] ?? 0).toString(),
          ) ??
          0.0,
      date: data['created_at'] ?? data['date'] ?? '',
      shippingCost:
          double.tryParse(
            (data['shipping_cost'] ?? data['shippingCost'] ?? 0).toString(),
          ) ??
          0.0,
      items: itemsList,
    );
  }
}

class OrderItemModel {
  final int productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final bool isReviewed;
  final int? myRating;
  final String? myComment;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    this.isReviewed = false,
    this.myRating,
    this.myComment,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // 🔥 الحل النهائي لمشكلة الصور (String vs List)
    String image = '';
    var rawImages = json['images'];

    try {
      if (rawImages != null) {
        if (rawImages is String && rawImages.isNotEmpty) {
          // إذا كان نصاً، نحاول فكه كمصفوفة JSON
          var decoded = jsonDecode(rawImages);
          if (decoded is List && decoded.isNotEmpty) {
            image = decoded[0].toString();
          }
        } else if (rawImages is List && rawImages.isNotEmpty) {
          // إذا كانت مصفوفة جاهزة
          image = rawImages[0].toString();
        }
      } else if (json['productImage'] != null) {
        image = json['productImage'].toString();
      }
    } catch (e) {
      debugPrint("❌ Error parsing images in OrderItem: $e");
    }

    return OrderItemModel(
      productId: json['product_id'] ?? json['id'] ?? 0,
      productName: json['productName'] ?? '',
      productImage: image,
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      // 🔥 قراءة حالة التقييم بشكل آمن (الباك إند يرسلها كـ 0/1 أو true/false)
      isReviewed: json['isReviewed'] == 1 || json['isReviewed'] == true,
      myRating:
          json['myRating'] != null
              ? int.tryParse(json['myRating'].toString())
              : null,
      myComment: json['myComment']?.toString(),
    );
  }
}
