import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Services & Screens
import 'package:linyora_project/features/auth/services/auth_service.dart';
import 'package:linyora_project/features/auth/screens/login_screen.dart';
import 'package:linyora_project/features/auth/screens/register_screen.dart';
import '../services/checkout_service.dart';

// Models
import '../../../models/checkout_models.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/payment_card_model.dart';

// Providers
import '../providers/cart_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/screens/add_card_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CheckoutService _checkoutService = CheckoutService();

  // State Variables
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isProcessing = false;

  List<AddressModel> _addresses = [];
  int? _selectedAddressId;
  List<MerchantGroup> _merchantGroups = []; // القائمة المقسمة
  String _paymentMethodType = 'card'; // 'card' or 'cod'
  String? _selectedCardId;

  // Colors
  final Color _primaryColor = const Color(0xFFF105C6);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // 1️⃣ التحقق من حالة تسجيل الدخول
  void _checkAuth() {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    setState(() => _isLoggedIn = isLoggedIn);

    // إذا كان مسجلاً، ابدأ بجلب البيانات
    if (isLoggedIn) {
      _initData();
    }
  }

  // 2️⃣ جلب البيانات (عناوين، بطاقات، تقسيم السلة)
  Future<void> _initData() async {
    setState(() => _isLoading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    if (cart.items.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      // جلب العناوين والبطاقات بالتوازي
      await Future.wait([_fetchAddresses(), paymentProvider.fetchCards()]);

      // تقسيم السلة وجلب خيارات الشحن لكل مجموعة
      await _prepareMerchantGroups(cart);

      // تعيين البطاقة الافتراضية
      if (paymentProvider.cards.isNotEmpty) {
        final defaultCard = paymentProvider.cards.firstWhere(
          (c) => c.isDefault,
          orElse: () => paymentProvider.cards.first,
        );
        _selectedCardId = defaultCard.id;
      }
    } catch (e) {
      print("Checkout Init Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء تحميل البيانات")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAddresses() async {
    final addresses = await _checkoutService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        if (addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddressId = defaultAddr.id;
        }
      });
    }
  }

  // 🔥 3️⃣ منطق تقسيم المنتجات وجلب الشحن المستقل
  Future<void> _prepareMerchantGroups(CartProvider cart) async {
    final Map<String, MerchantGroup> groupsMap = {};

    // أ. التجميع المحلي
    for (var item in cart.items) {
      // تحديد المالك (تاجر أو مورد)
      final bool isDropshipping = item.product.isDropshipping ?? false;
      final String ownerId =
          isDropshipping
              ? (item.product.merchantId?.toString() ?? '0')
              : (item.product.merchantId.toString());

      final String prefix = isDropshipping ? 'sup-' : 'mer-';
      final String groupId = "$prefix$ownerId";
      final String ownerName =
          isDropshipping
              ? (item.product.merchantName ?? "مورد")
              : item.product.merchantName;

      if (!groupsMap.containsKey(groupId)) {
        groupsMap[groupId] = MerchantGroup(
          groupId: ownerId,
          merchantName: ownerName,
          items: [],
        );
      }
      groupsMap[groupId]!.items.add(item);
    }

    final List<MerchantGroup> tempGroups = groupsMap.values.toList();

    // ب. جلب خيارات الشحن لكل مجموعة من السيرفر
    await Future.wait(
      tempGroups.map((group) async {
        try {
          final productIds = group.items.map((e) => e.product.id).toList();
          final options = await _checkoutService.getShippingOptions(productIds);

          group.shippingOptions = options;

          // اختيار أول خيار شحن افتراضياً
          if (options.isNotEmpty) {
            group.selectedShipping = options.first;
          }
        } catch (e) {
          print("Error fetching shipping for ${group.merchantName}: $e");
        }
      }),
    );

    if (mounted) {
      setState(() {
        _merchantGroups = tempGroups;
      });
    }
  }

  double get _totalShippingCost {
    return _merchantGroups.fold(0.0, (sum, group) {
      return sum + (group.selectedShipping?.cost ?? 0.0);
    });
  }

  // التنقل
  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => _checkAuth());
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    ).then((_) => _checkAuth());
  }

  // 4️⃣ تنفيذ الدفع
  Future<void> _handlePayment() async {
    // التحقق من البيانات
    if (_selectedAddressId == null) {
      _showError('الرجاء اختيار عنوان شحن');
      return;
    }

    bool missingShipping = _merchantGroups.any(
      (g) => g.shippingOptions.isNotEmpty && g.selectedShipping == null,
    );
    if (missingShipping) {
      _showError('الرجاء اختيار طريقة شحن لكل تاجر');
      return;
    }

    if (_paymentMethodType == 'card' && _selectedCardId == null) {
      _showError('الرجاء اختيار بطاقة للدفع');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final totalAmount = cart.totalAmount + _totalShippingCost;

      // تجهيز البيانات للباك إند
      final shippingSelections =
          _merchantGroups.map((g) {
            return {
              'merchant_id': g.groupId,
              'shipping_option_id': g.selectedShipping?.id,
            };
          }).toList();

      if (_paymentMethodType == 'cod') {
        await _checkoutService.placeCodOrder(
          cartItems: cart.items,
          addressId: _selectedAddressId!,
          shippingSelections: shippingSelections,
          shippingCost: _totalShippingCost,
          totalAmount: totalAmount,
        );
      } else {
        await _checkoutService.placeCardOrder(
          cartItems: cart.items,
          addressId: _selectedAddressId!,
          shippingSelections: shippingSelections,
          shippingCost: _totalShippingCost,
          totalAmount: totalAmount,
          paymentMethodId: _selectedCardId!,
        );
      }

      // نجاح
      cart.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الطلب بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // أو الانتقال لصفحة النجاح
      }
    } catch (e) {
      _showError('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    // الحالة 1: غير مسجل دخول (Soft Auth Wall)
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "إتمام الطلب",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: _buildAuthRequiredView(),
      );
    }

    // الحالة 2: جاري التحميل
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // الحالة 3: عرض صفحة الدفع
    final cart = Provider.of<CartProvider>(context);
    final subTotal = cart.totalAmount;
    final total = subTotal + _totalShippingCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "إتمام الطلب",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAddressSection(),
            const SizedBox(height: 20),

            if (_merchantGroups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("جاري معالجة المنتجات..."),
              )
            else
              ..._merchantGroups
                  .map((group) => _buildMerchantGroupCard(group))
                  .toList(),

            const SizedBox(height: 20),
            _buildPaymentMethodSection(),
            const SizedBox(height: 20),
            _buildSummarySection(subTotal, total),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    _isProcessing
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          "ادفع ${total.toStringAsFixed(2)} ر.س",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildAuthRequiredView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_person_outlined,
              size: 64,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "تسجيل الدخول لإكمال الطلب",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "لإتمام عملية الشراء وحفظ عنوانك وتتبع طلبك، يرجى تسجيل الدخول إلى حسابك.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(Icons.check_circle, "حفظ عناوين الشحن لتسريع الطلب"),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.check_circle, "تتبع حالة الطلب خطوة بخطوة"),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.check_circle, "إدارة المرتجعات بسهولة"),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "تسجيل الدخول",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _goToRegister,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "إنشاء حساب جديد",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "عنوان الشحن",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_addresses.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    /* Navigate to add address */
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("إضافة عنوان جديد"),
                ),
              )
            else
              Column(
                children:
                    _addresses
                        .map(
                          (addr) => InkWell(
                            onTap:
                                () => setState(
                                  () => _selectedAddressId = addr.id,
                                ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      _selectedAddressId == addr.id
                                          ? _primaryColor
                                          : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    _selectedAddressId == addr.id
                                        ? Colors.purple.withOpacity(0.05)
                                        : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (addr.isDefault)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  "افتراضي",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${addr.city}, ${addr.addressLine1}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          addr.phone,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedAddressId == addr.id)
                                    Icon(
                                      Icons.check_circle,
                                      color: _primaryColor,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة التاجر مع خيارات الشحن
  Widget _buildMerchantGroupCard(MerchantGroup group) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  group.merchantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            ...group.items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl:
                                item.selectedVariant.images.isNotEmpty
                                    ? item.selectedVariant.images[0]
                                    : '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${item.quantity} x ${item.selectedVariant.price} ر.س",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${(item.quantity * item.selectedVariant.price).toStringAsFixed(0)} ر.س",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "طريقة الشحن",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (group.shippingOptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "لا توجد خيارات شحن متاحة لهذا العنوان",
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    )
                  else
                    Column(
                      children:
                          group.shippingOptions
                              .map(
                                (opt) => RadioListTile<int>(
                                  value: opt.id,
                                  groupValue: group.selectedShipping?.id,
                                  activeColor: _primaryColor,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    opt.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle:
                                      opt.estimatedDays != null
                                          ? Text(
                                            "يصل خلال ${opt.estimatedDays} أيام",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                          : null,
                                  secondary: Text(
                                    "${opt.cost} ر.س",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      group.selectedShipping = opt;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "طريقة الدفع",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => _paymentMethodType = 'card'),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'card',
                        groupValue: _paymentMethodType,
                        activeColor: _primaryColor,
                        onChanged:
                            (val) => setState(() => _paymentMethodType = val!),
                      ),
                      const Text(
                        "بطاقة ائتمان / مدى",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (_paymentMethodType == 'card') ...[
                  if (paymentProvider.cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 32, top: 8),
                      child: Text(
                        "لا توجد بطاقات محفوظة",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    )
                  else
                    Column(
                      children:
                          paymentProvider.cards
                              .map((card) => _buildSavedCardItem(card))
                              .toList(),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 12),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddCardScreen(),
                          ),
                        ).then((_) {
                          paymentProvider.fetchCards();
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text("إضافة بطاقة جديدة"),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryColor,
                      ),
                    ),
                  ),
                ],
                const Divider(height: 24),
                InkWell(
                  onTap:
                      () => setState(() {
                        _paymentMethodType = 'cod';
                        _selectedCardId = null;
                      }),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'cod',
                        groupValue: _paymentMethodType,
                        activeColor: _primaryColor,
                        onChanged:
                            (val) => setState(() {
                              _paymentMethodType = val!;
                              _selectedCardId = null;
                            }),
                      ),
                      const Text("الدفع عند الاستلام"),
                      const Spacer(),
                      const Icon(Icons.money, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedCardItem(PaymentCardModel card) {
    bool isSelected = _selectedCardId == card.id;
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? _primaryColor : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
        color: isSelected ? Colors.purple.withOpacity(0.05) : Colors.white,
      ),
      child: RadioListTile<String>(
        value: card.id,
        groupValue: _selectedCardId,
        activeColor: _primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Row(
          children: [
            const Icon(Icons.credit_card, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              "•••• ${card.last4}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text(
              card.expiryDateFormatted,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        onChanged: (val) {
          setState(() {
            _selectedCardId = val;
            _paymentMethodType = 'card';
          });
        },
      ),
    );
  }

  Widget _buildSummarySection(double subTotal, double total) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                const Text(
                  "الإجمالي",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${total.toStringAsFixed(2)} ر.س",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "جميع المعاملات آمنة ومشفرة 100%",
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
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
        Text(
          "${amount.toStringAsFixed(2)} ر.س",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
