import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/dashboards/MyStore/models/merchant_profile_model.dart';
import 'package:linyora_project/features/dashboards/MyStore/services/merchant_service.dart';
import 'package:linyora_project/features/products/screens/add_edit_product_screen.dart';
import 'package:linyora_project/features/public_profiles/screens/merchant_profile_screen.dart';
import 'package:linyora_project/features/settings/screens/settings_screen.dart';
import '../../../../models/product_model.dart';

class MyStoreScreen extends StatefulWidget {
  const MyStoreScreen({Key? key}) : super(key: key);

  @override
  State<MyStoreScreen> createState() => _MyStoreScreenState();
}

class _MyStoreScreenState extends State<MyStoreScreen> {
  final MerchantService _service = MerchantService();
  bool _isLoading = true;
  MerchantProfileModel? _storeProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _service.getMyStoreProfile();
      if (mounted) {
        setState(() {
          _storeProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "فشل تحميل بيانات المتجر";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF105C6)),
        ),
      );
    }

    if (_errorMessage != null || _storeProfile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage ?? "لا توجد بيانات للمتجر"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStoreData,
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ),
        ),
      );
    }

    // --- حسابات التجاوب ---
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    double childAspectRatio = 0.7;

    return Scaffold(
      backgroundColor: Colors.white,

      // زر إضافة منتج جديد
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // ننتظر حتى يعود المستخدم من صفحة الإضافة
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      const AddEditProductScreen(), // بدون تمرير منتج = وضع الإضافة
            ),
          );
          // عند العودة، نحدث البيانات لرؤية المنتج الجديد
          _loadStoreData();
        },
        backgroundColor: const Color(0xFFF105C6),
        icon: const Icon(Icons.add),
        label: const Text("منتج جديد"),
      ),

      body: CustomScrollView(
        slivers: [
          // 1. الغلاف (Cover)
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF105C6),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  // الانتقال لصفحة الإعدادات
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  // أو عرض رسالة مؤقتة إذا لم تكن الصفحة جاهزة
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content: Text("صفحة الإعدادات قادمة قريباً"),
                  //   ),
                  // );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _storeProfile!.coverUrl != null &&
                          _storeProfile!.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: _storeProfile!.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) => Container(color: Colors.grey[200]),
                        errorWidget:
                            (c, u, e) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                      )
                      : Container(color: Colors.grey[300]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. محتوى البروفايل
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // الصورة الشخصية
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage:
                              _storeProfile!.profileUrl != null
                                  ? CachedNetworkImageProvider(
                                    _storeProfile!.profileUrl!,
                                  )
                                  : null,
                          child:
                              _storeProfile!.profileUrl == null
                                  ? Text(
                                    _storeProfile!.storeName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _storeProfile!.storeName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // الشارات (Badges)
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (_storeProfile!.isVerified)
                            _buildBadge(Icons.verified, "موثوق", Colors.blue),
                          _buildBadge(
                            Icons.star,
                            "${_storeProfile!.rating}",
                            Colors.orange,
                          ),
                          if (_storeProfile!.isDropshipper)
                            _buildBadge(
                              Icons.cloud_download,
                              "Dropshipper",
                              Colors.purple,
                            ),
                        ],
                      ),
                    ],
                  ),

                  // أزرار التحكم
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("تعديل المتجر"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // ✅ التأكد من أن البيانات محملة قبل الانتقال
                              if (_storeProfile != null) {
                                print(_storeProfile!.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => MerchantProfileScreen(
                                          // ✅ هنا نمرر الـ ID الخاص بالمتجر الحالي
                                          // بما أن ID في المودل int والشاشة تطلب String، نستخدم toString()
                                          merchantId:
                                              _storeProfile!.id.toString(),
                                        ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text("معاينة كزائر"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الوصف (Bio)
                  if (_storeProfile!.bio != null)
                    Text(
                      _storeProfile!.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                  const SizedBox(height: 20),

                  // لوحة الإحصائيات (Dashboard Stats)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          "المبيعات",
                          "${_storeProfile!.totalSales}",
                          Icons.monetization_on,
                          Colors.green,
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          "المنتجات",
                          "${_storeProfile!.activeProductsCount}",
                          Icons.inventory_2,
                          Colors.orange,
                        ),
                        _buildVerticalDivider(),
                        _buildStatItem(
                          "المتابعين",
                          "${_storeProfile!.followersCount}",
                          Icons.people,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Row(
                    children: [
                      Icon(Icons.grid_view_rounded, color: Color(0xFFF105C6)),
                      SizedBox(width: 8),
                      Text(
                        "منتجاتي",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // 3. شبكة المنتجات الحقيقية
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver:
                _storeProfile!.products.isEmpty
                    ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text(
                            "لا توجد منتجات حتى الآن",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                    : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _storeProfile!.products[index];
                        return _MyProductCard(
                          product: product,
                          onEdit: () async {
                            // ✅ هنا الربط الحقيقي لتعديل المنتج
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AddEditProductScreen(
                                      product: product,
                                    ), // تمرير المنتج = وضع التعديل
                              ),
                            );
                            // تحديث الصفحة لرؤية التعديلات (مثل السعر الجديد)
                            _loadStoreData();
                          },
                        );
                      }, childCount: _storeProfile!.products.length),
                    ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value == "0" && label == "المبيعات"
              ? "-"
              : value, // عرض شرطة إذا لم تتوفر المبيعات
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }
}

// كارت المنتج الحقيقي
class _MyProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;

  const _MyProductCard({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Colors.grey[100]),
                    errorWidget:
                        (c, u, e) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                // زر التعديل
                Positioned(
                  top: 8,
                  left: 8,
                  child: InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // شارة دروب شيبينج إذا كان المنتج مستورداً
                if (product.isDropshipping)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.cloud_download,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${product.price} ر.س",
                      style: const TextStyle(
                        color: Color(0xFFF105C6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (product.stock <= 5)
                      Text(
                        "باقي ${product.stock}",
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
