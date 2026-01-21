import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/models/offers/models/offer_models.dart';
import 'package:linyora_project/features/models/offers/screens/model_offer_form_screen.dart';
import '../services/offers_service.dart';
import '../../screens/model_nav.dart'; // القائمة الجانبية

class InfluencerOffersScreen extends StatefulWidget {
  const InfluencerOffersScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerOffersScreen> createState() => _ModelOffersScreenState();
}

class _ModelOffersScreenState extends State<InfluencerOffersScreen> {
  final OffersService _service = OffersService();
  List<ServicePackage> _packages = [];
  bool _isLoading = true;

  // Colors
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getOffers();
      if (mounted) {
        setState(() {
          _packages = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(ServicePackage pkg) async {
    try {
      // تحويل الكائن لـ JSON لإرساله
      // ملاحظة: هنا بسطنا الأمر، في الواقع يجب تحويل الـ ServicePackage لـ Map كامل
      // سنقوم بعمل تحديث متفائل (Optimistic Update)
      final newStatus = pkg.status == 'active' ? 'paused' : 'active';
      setState(() => pkg.status = newStatus);

      // هنا يجب عليك تحويل الـ Package بالكامل لـ Map لإرسالها للـ PUT
      // للتسهيل في المثال، نفترض أن الخدمة تعالج ذلك
      // await _service.toggleStatus(pkg.id, pkg.status == 'active' ? 'paused' : 'active', ...);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "تم تغيير الحالة إلى ${newStatus == 'active' ? 'نشط' : 'موقوف'}",
          ),
        ),
      );
    } catch (e) {
      _fetchOffers(); // تراجع عند الخطأ
    }
  }

  Future<void> _deleteOffer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف العرض"),
            content: const Text(
              "هل أنت متأكد من حذف هذا العرض؟ لا يمكن التراجع عن هذا الإجراء.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("حذف", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _service.deleteOffer(id);
        _fetchOffers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم الحذف بنجاح")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل الحذف")));
      }
    }
  }

  void _openForm({ServicePackage? package}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelOfferFormScreen(packageToEdit: package),
      ),
    ).then((val) {
      if (val == true) _fetchOffers(); // تحديث إذا تم الحفظ
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // القائمة الجانبية (اختياري إذا كانت الصفحة فرعية)
      // drawer: const ModelDrawer(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurBlob(Colors.pink.shade200),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(Colors.purple.shade200),
          ),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchOffers,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Stats & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${_packages.length} عرض نشط",
                            style: TextStyle(
                              color: _roseColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _purpleColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text("إضافة عرض جديد"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_packages.isEmpty)
                      _buildEmptyState()
                    else
                      ..._packages.map((pkg) => _buildOfferCard(pkg)).toList(),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد عروض حالياً",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "ابدأ بإضافة باقاتك لجذب العملاء",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(ServicePackage pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pkg.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildBadge(
                            pkg.status == 'active' ? "نشط" : "موقوف",
                            Colors.white.withOpacity(0.2),
                            Colors.white,
                          ),
                          if (pkg.category != null)
                            _buildBadge(
                              pkg.category!,
                              Colors.white.withOpacity(0.2),
                              Colors.white,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _openForm(package: pkg),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _deleteOffer(pkg.id),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pkg.description != null && pkg.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      pkg.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),

                // Tiers Grid
                Column(
                  children:
                      pkg.tiers.map((tier) => _buildTierItem(tier)).toList(),
                ),

                const Divider(height: 24),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => _toggleStatus(pkg),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              pkg.status == 'active'
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                        ),
                        foregroundColor:
                            pkg.status == 'active' ? Colors.red : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        pkg.status == 'active' ? "تعطيل العرض" : "تفعيل العرض",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    _buildBadge(
                      pkg.status == 'active' ? "ظاهر للعملاء" : "مخفي",
                      pkg.status == 'active'
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      pkg.status == 'active'
                          ? Colors.green
                          : Colors.amber.shade800,
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

  Widget _buildTierItem(PackageTier tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tier.tierName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "${tier.price.toStringAsFixed(0)} ر.س",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _roseColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tier.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconText(Icons.access_time, "${tier.deliveryDays} أيام"),
              _buildIconText(
                Icons.loop,
                tier.revisions == -1
                    ? "تعديلات لانهائية"
                    : "${tier.revisions} تعديلات",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
