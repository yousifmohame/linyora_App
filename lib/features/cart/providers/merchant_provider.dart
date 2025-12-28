import 'package:linyora_project/models/cart_item_model.dart';
import 'package:linyora_project/models/checkout_models.dart';


class MerchantGroup {
  final String groupId; // merchantId or supplierId
  final String merchantName;
  final List<CartItemModel> items;
  List<ShippingOption> shippingOptions;
  ShippingOption? selectedShipping;

  MerchantGroup({
    required this.groupId,
    required this.merchantName,
    required this.items,
    this.shippingOptions = const [],
    this.selectedShipping,
  });
}