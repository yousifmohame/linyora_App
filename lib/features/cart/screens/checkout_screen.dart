import 'package:flutter/material.dart';
import 'package:linyora_project/features/cart/providers/merchant_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/color_helper.dart'; // لتنسيق الألوان
import '../../../models/checkout_models.dart';
import '../../../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../services/checkout_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CheckoutService _checkoutService = CheckoutService();
  
  bool _isLoading = true;
  bool _isProcessing = false; // عند ضغط زر الدفع
  
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;
  
  List<MerchantGroup> _merchantGroups = [];
  String _paymentMethod = 'card'; // 'card' or 'cod'

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // تجهيز البيانات الأولية (تجميع المنتجات + جلب العناوين والشحن)
  Future<void> _initData() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      // 1. جلب العناوين
      final addresses = await _checkoutService.getAddresses();
      
      // 2. تجميع المنتجات (Client-side Grouping)
      final Map<String, MerchantGroup> groupsMap = {};
      
      for (var item in cart.items) {
        // افتراض: ProductDetailsModel يحتوي على merchantName و merchantId
        // إذا كان دروبشيبينغ نستخدم supplierId (تحتاج لتوفير هذه البيانات في المودل)
        // للتبسيط سنعتمد على التاجر الأساسي حالياً
        final merchantId = item.product.merchantId.toString(); // يفضل استخدام ID فريد
        final groupId = "mer-$merchantId"; // مفتاح للمجموعة

        if (!groupsMap.containsKey(groupId)) {
          groupsMap[groupId] = MerchantGroup(
            groupId: merchantId, // هنا المفروض ID التاجر الحقيقي
            merchantName: item.product.merchantName,
            items: [],
          );
        }
        groupsMap[groupId]!.items.add(item);
      }

      final groups = groupsMap.values.toList();

      // 3. جلب خيارات الشحن لكل مجموعة
      for (var group in groups) {
        final productIds = group.items.map((e) => e.product.id).toList();
        final options = await _checkoutService.getShippingOptions(productIds);
        
        group.shippingOptions = options;
        if (options.isNotEmpty) {
          group.selectedShipping = options.first; // اختيار الافتراضي
        }
      }

      if (mounted) {
        setState(() {
          _addresses = addresses;
          // اختيار العنوان الافتراضي
          if (addresses.isNotEmpty) {
            final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
            _selectedAddressId = defaultAddr.id;
          }
          _merchantGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Checkout Init Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // حساب تكلفة الشحن الكلية
  double get _totalShippingCost {
    return _merchantGroups.fold(0.0, (sum, group) {
      return sum + (group.selectedShipping?.cost ?? 0.0);
    });
  }

  // تنفيذ الدفع
  Future<void> _handlePayment() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار عنوان شحن')));
      return;
    }

    // التحقق من اختيار شركة شحن لكل تاجر
    for (var group in _merchantGroups) {
      if (group.shippingOptions.isNotEmpty && group.selectedShipping == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء اختيار طريقة شحن لـ ${group.merchantName}')));
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      
      // تجهيز خيارات الشحن للباك اند
      final shippingSelections = _merchantGroups.map((g) {
        return {
          'merchant_id': g.groupId, // تأكد أنه ID رقمي إذا كان الباك اند يطلبه
          'shipping_option_id': g.selectedShipping?.id
        };
      }).toList();

      if (_paymentMethod == 'cod') {
        await _checkoutService.placeCodOrder(
          cartItems: cart.items,
          addressId: _selectedAddressId!,
          shippingSelections: shippingSelections,
          shippingCost: _totalShippingCost,
        );
        
        // نجاح
        cart.clearCart();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/checkout/success'); // أو صفحة نجاح مخصصة
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الطلب بنجاح!'), backgroundColor: Colors.green));
        }
      } else {
        // منطق الدفع بالبطاقة (Stripe)
        // يتطلب package: flutter_stripe
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الدفع بالبطاقة يتطلب إعداد Stripe')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final subTotal = cart.totalAmount;
    final total = subTotal + _totalShippingCost;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("إتمام الطلب", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. قسم العنوان
            _buildAddressSection(),
            const SizedBox(height: 20),

            // 2. المنتجات والشحن (مجمعة)
            ..._merchantGroups.map((group) => _buildMerchantGroupCard(group)).toList(),
            const SizedBox(height: 20),

            // 3. طريقة الدفع
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),

            // 4. الملخص
            _buildSummarySection(subTotal, total),
            const SizedBox(height: 30),

            // زر الدفع
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF105C6), // لون البراند
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("ادفع ${total.toStringAsFixed(2)} ر.س", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildAddressSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.location_on, color: Color(0xFFF105C6)), SizedBox(width: 8), Text("عنوان الشحن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            if (_addresses.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () { /* فتح مودال إضافة عنوان */ },
                  icon: const Icon(Icons.add),
                  label: const Text("إضافة عنوان جديد"),
                ),
              )
            else
              Column(
                children: _addresses.map((addr) => 
                  InkWell(
                    onTap: () => setState(() => _selectedAddressId = addr.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _selectedAddressId == addr.id ? const Color(0xFFF105C6) : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedAddressId == addr.id ? Colors.purple.withOpacity(0.05) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (addr.isDefault) 
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                        child: const Text("افتراضي", style: TextStyle(fontSize: 10)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text("${addr.city}, ${addr.addressLine1}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Text(addr.phone, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          if (_selectedAddressId == addr.id)
                            const Icon(Icons.check_circle, color: Color(0xFFF105C6)),
                        ],
                      ),
                    ),
                  )
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantGroupCard(MerchantGroup group) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.store, color: Colors.blue), const SizedBox(width: 8), Text(group.merchantName, style: const TextStyle(fontWeight: FontWeight.bold))]),
            const Divider(height: 24),
            // المنتجات
            ...group.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(imageUrl: item.selectedVariant.images.isNotEmpty ? item.selectedVariant.images[0] : '', width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text("${item.quantity} x ${item.selectedVariant.price} ر.س", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text("${(item.quantity * item.selectedVariant.price).toStringAsFixed(0)} ر.س", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            // خيارات الشحن
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.local_shipping_outlined, size: 16), SizedBox(width: 8), Text("طريقة الشحن", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
                  const SizedBox(height: 8),
                  if (group.shippingOptions.isEmpty)
                    const Text("لا توجد خيارات شحن متاحة", style: TextStyle(color: Colors.orange, fontSize: 12))
                  else
                    Column(
                      children: group.shippingOptions.map((opt) => 
                        RadioListTile<int>(
                          value: opt.id,
                          groupValue: group.selectedShipping?.id,
                          activeColor: const Color(0xFFF105C6),
                          contentPadding: EdgeInsets.zero,
                          title: Text(opt.name, style: const TextStyle(fontSize: 13)),
                          subtitle: opt.estimatedDays != null ? Text("${opt.estimatedDays} أيام", style: const TextStyle(fontSize: 11)) : null,
                          secondary: Text("${opt.cost} ر.س", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          onChanged: (val) {
                            setState(() {
                              group.selectedShipping = opt;
                            });
                          },
                        )
                      ).toList(),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.payment, color: Colors.green), SizedBox(width: 8), Text("طريقة الدفع", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            _buildPaymentRadio("card", "بطاقة ائتمان / مدى", Icons.credit_card),
            const SizedBox(height: 10),
            _buildPaymentRadio("cod", "الدفع عند الاستلام", Icons.money),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFFF105C6) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.purple.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFF105C6) : Colors.grey),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFF105C6)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(double subTotal, double total) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow("المجموع الفرعي", subTotal),
            const SizedBox(height: 8),
            _summaryRow("الشحن", _totalShippingCost),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("الإجمالي", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${total.toStringAsFixed(2)} ر.س", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF105C6))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text("جميع المعاملات آمنة ومشفرة 100%", style: TextStyle(fontSize: 11, color: Colors.blue))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text("${amount.toStringAsFixed(2)} ر.س", style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}