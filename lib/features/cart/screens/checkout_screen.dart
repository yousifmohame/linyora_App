import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

// Services & Screens
import 'package:linyora_project/features/auth/services/auth_service.dart';
import 'package:linyora_project/features/auth/screens/login_screen.dart';
import 'package:linyora_project/features/auth/screens/register_screen.dart';
import 'package:linyora_project/features/address/screens/add_edit_address_screen.dart'; // Ensure this path is correct
import '../services/checkout_service.dart';

// Models
import '../../../models/checkout_models.dart';
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
  List<MerchantGroup> _merchantGroups = []; // The grouped list
  String _paymentMethodType = 'card'; // 'card' or 'cod'
  String? _selectedCardId;

  // 🔥 New Variable for COD Fee
  double _codFee = 0.0;

  // Colors
  final Color _primaryColor = const Color(0xFFF105C6);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // 1️⃣ Check Login Status
  void _checkAuth() {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    setState(() => _isLoggedIn = isLoggedIn);

    if (isLoggedIn) {
      _initData();
    }
  }

  // 2️⃣ Fetch Data (Addresses, Cards, Settings, Cart Grouping)
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
      final results = await Future.wait([
        _checkoutService.getAddresses(),
        paymentProvider.fetchCards(),
        _checkoutService.getPaymentSettings(),
      ]);

      final addresses = results[0] as List<AddressModel>;
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

      final settings = results[2] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _codFee = double.tryParse(settings['cod_fee'].toString()) ?? 0.0;
        });
      }

      await _prepareMerchantGroups(cart);

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
        final l10n =
            AppLocalizations.of(context)!; // ✅ الحصول على الترجمة للخطأ
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.dataLoadError)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 3️⃣ Logic to Group Items & Fetch Independent Shipping
  Future<void> _prepareMerchantGroups(CartProvider cart) async {
    final Map<String, MerchantGroup> groupsMap = {};

    for (var item in cart.items) {
      final bool isDropshipping = item.product.isDropshipping ?? false;
      final String ownerId =
          isDropshipping
              ? (item.product.merchantId?.toString() ?? '0')
              : (item.product.merchantId.toString());

      final String prefix = isDropshipping ? 'sup-' : 'mer-';
      final String groupId = "$prefix$ownerId";

      // ✅ نترجم كلمة مورد في حالة لم يكن هناك اسم
      final l10n = mounted ? AppLocalizations.of(context)! : null;
      final String fallbackName = l10n?.supplierLabel ?? "مورد";

      final String ownerName =
          isDropshipping
              ? (item.product.merchantName ?? fallbackName)
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

    await Future.wait(
      tempGroups.map((group) async {
        try {
          final productIds = group.items.map((e) => e.product.id).toList();
          final options = await _checkoutService.getShippingOptions(productIds);
          group.shippingOptions = options;
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

  Future<void> _fetchAddresses() async {
    final addresses = await _checkoutService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        if (_selectedAddressId == null && addresses.isNotEmpty) {
          final defaultAddr = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddressId = defaultAddr.id;
        }
      });
    }
  }

  double get _totalShippingCost {
    return _merchantGroups.fold(0.0, (sum, group) {
      return sum + (group.selectedShipping?.cost ?? 0.0);
    });
  }

  // Navigation Helpers
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

  Future<void> _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    );

    if (result == true) {
      await _fetchAddresses();
    }
  }

  // 4️⃣ Execute Payment
  Future<void> _handlePayment(AppLocalizations l10n) async {
    if (_selectedAddressId == null) {
      _showError(l10n.selectShippingAddressMsg); // ✅ مترجم
      return;
    }

    bool missingShipping = _merchantGroups.any(
      (g) => g.shippingOptions.isNotEmpty && g.selectedShipping == null,
    );
    if (missingShipping) {
      _showError(l10n.selectShippingMethodMsg); // ✅ مترجم
      return;
    }

    if (_paymentMethodType == 'card' && _selectedCardId == null) {
      _showError(l10n.selectPaymentCardMsg); // ✅ مترجم
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final currentCodFee = _paymentMethodType == 'cod' ? _codFee : 0.0;
      final totalAmount = cart.totalAmount + _totalShippingCost + currentCodFee;

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
          codFee: _codFee,
        );
      } else {
        await _checkoutService.placeCardOrder(
          cartItems: cart.items,
          addressId: _selectedAddressId!,
          shippingSelections: shippingSelections,
          shippingCost: _totalShippingCost,
          paymentMethodId: _selectedCardId!,
          totalAmount: totalAmount,
        );
      }

      cart.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderSuccessMsg), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(
        '${l10n.errorOccurredMsg}${e.toString().replaceAll('Exception:', '')}',
      ); // ✅ مترجم
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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            l10n.checkoutTitle, // ✅ مترجم
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
        ),
        body: _buildAuthRequiredView(l10n), // ✅ تمرير l10n
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cart = Provider.of<CartProvider>(context);
    final subTotal = cart.totalAmount;
    final currentCodFee = _paymentMethodType == 'cod' ? _codFee : 0.0;
    final total = subTotal + _totalShippingCost + currentCodFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          l10n.checkoutTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAddressSection(l10n), // ✅ تمرير l10n
            const SizedBox(height: 20),

            if (_merchantGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.processingProducts), // ✅ مترجم
              )
            else
              ..._merchantGroups
                  .map(
                    (group) => _buildMerchantGroupCard(group, l10n),
                  ) // ✅ تمرير l10n
                  .toList(),

            const SizedBox(height: 20),
            _buildPaymentMethodSection(l10n), // ✅ تمرير l10n
            const SizedBox(height: 20),
            _buildSummarySection(subTotal, total, l10n), // ✅ تمرير l10n
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isProcessing
                        ? null
                        : () => _handlePayment(l10n), // ✅ تمرير l10n
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
                          "${l10n.payBtn} ${total.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ ديناميكي ومترجم
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

  Widget _buildAuthRequiredView(AppLocalizations l10n) {
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
          Text(
            l10n.loginToCompleteOrder, // ✅ مترجم
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.loginToCompleteOrderDesc, // ✅ مترجم
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(
            Icons.check_circle,
            l10n.saveAddressesFeature,
          ), // ✅ مترجم
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.check_circle,
            l10n.trackOrderFeature,
          ), // ✅ مترجم
          const SizedBox(height: 12),
          _buildFeatureRow(
            Icons.check_circle,
            l10n.easyReturnsFeature,
          ), // ✅ مترجم
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
              child: Text(
                l10n.loginBtn, // ✅ مترجم
                style: const TextStyle(
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
              child: Text(
                l10n.createAccountBtn, // ✅ مترجم
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _buildAddressSection(AppLocalizations l10n) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      l10n.shippingAddressTitle, // ✅ مترجم
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_addresses.isNotEmpty)
                  TextButton(
                    onPressed: _navigateToAddAddress,
                    child: Text(
                      l10n.addBtn, // ✅ مترجم
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_addresses.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: _navigateToAddAddress,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addNewAddressBtn), // ✅ مترجم
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
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
                                                  left: 8,
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
                                                child: Text(
                                                  l10n.defaultAddressLabel, // ✅ مترجم
                                                  style: const TextStyle(
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

  Widget _buildMerchantGroupCard(MerchantGroup group, AppLocalizations l10n) {
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

            ...group.items.map((item) {
              final variant = item.selectedVariant;
              final String image =
                  (variant != null && variant.images.isNotEmpty)
                      ? variant.images[0]
                      : item.product.imageUrl;
              final double price = variant?.price ?? item.product.price;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: image,
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (variant != null)
                            Text(
                              variant.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          Text(
                            "${item.quantity} x ${price.toStringAsFixed(0)} ${l10n.currencySAR}", // ✅ عملة مترجمة
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${(item.quantity * price).toStringAsFixed(0)} ${l10n.currencySAR}", // ✅ عملة مترجمة
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),

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
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shippingMethodTitle, // ✅ مترجم
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (group.shippingOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        l10n.noShippingOptions, // ✅ مترجم
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Column(
                      children:
                          group.shippingOptions.map((opt) {
                            return RadioListTile<int>(
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
                                        "${l10n.arrivesIn} ${opt.estimatedDays} ${l10n.daysLabel}", // ✅ مترجم (ديناميكي)
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                      : null,
                              secondary: Text(
                                "${opt.cost} ${l10n.currencySAR}", // ✅ عملة مترجمة
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
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(AppLocalizations l10n) {
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
                Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      l10n.paymentMethodTitle, // ✅ مترجم
                      style: const TextStyle(
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
                      Text(
                        l10n.creditCardMada, // ✅ مترجم
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                if (_paymentMethodType == 'card') ...[
                  if (paymentProvider.cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 32, top: 8),
                      child: Text(
                        l10n.noSavedCards, // ✅ مترجم
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
                      label: Text(l10n.addNewCardBtn), // ✅ مترجم
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
                      Text(l10n.cashOnDelivery), // ✅ مترجم
                      if (_codFee > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "(+${_codFee.toStringAsFixed(0)} ${l10n.currencySAR} ${l10n.feeLabel})", // ✅ ديناميكي ومترجم
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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

  Widget _buildSummarySection(
    double subTotal,
    double total,
    AppLocalizations l10n,
  ) {
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
            _summaryRow(l10n.subtotalLabel, subTotal, l10n), // ✅ مترجم
            const SizedBox(height: 8),
            _summaryRow(
              l10n.shippingCostLabel,
              _totalShippingCost,
              l10n,
            ), // ✅ مترجم

            if (_paymentMethodType == 'cod' && _codFee > 0) ...[
              const SizedBox(height: 8),
              _summaryRow(
                l10n.codFeeDisplay,
                _codFee,
                l10n,
                isFee: true,
              ), // ✅ مترجم
            ],

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.grandTotalLabel, // ✅ مترجم
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${total.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ عملة مترجمة
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
              child: Row(
                children: [
                  const Icon(Icons.verified_user, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.secureTransactions, // ✅ مترجم
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
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

  Widget _summaryRow(
    String label,
    double amount,
    AppLocalizations l10n, {
    bool isFee = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isFee ? Colors.orange.shade800 : Colors.grey[600],
          ),
        ),
        Text(
          "${amount.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ عملة مترجمة
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isFee ? Colors.orange.shade800 : Colors.black,
          ),
        ),
      ],
    );
  }
}
