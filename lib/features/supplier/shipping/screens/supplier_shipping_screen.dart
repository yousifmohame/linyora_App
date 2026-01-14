import 'package:flutter/material.dart';
import 'package:linyora_project/features/supplier/shipping/models/supplier_shipping_models.dart';
import 'package:linyora_project/features/supplier/shipping/services/supplier_shipping_service.dart';

class SupplierShippingScreen extends StatefulWidget {
  const SupplierShippingScreen({Key? key}) : super(key: key);

  @override
  State<SupplierShippingScreen> createState() => _SupplierShippingScreenState();
}

class _SupplierShippingScreenState extends State<SupplierShippingScreen> {
  final SupplierShippingService _service = SupplierShippingService();
  List<ShippingCompany> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final data = await _service.getShippingCompanies();
      if (mounted)
        setState(() {
          _companies = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // نافذة الإضافة/التعديل
  void _showFormDialog({ShippingCompany? company}) {
    final nameCtrl = TextEditingController(text: company?.name ?? '');
    final costCtrl = TextEditingController(
      text: company?.shippingCost.toString() ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    company == null ? "إضافة شركة شحن" : "تعديل شركة الشحن",
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "اسم الشركة",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "تكلفة الشحن",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("إلغاء"),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                final name = nameCtrl.text;
                                final cost = double.tryParse(costCtrl.text);

                                if (name.isEmpty || cost == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("يرجى إدخال بيانات صحيحة"),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isSaving = true);
                                try {
                                  if (company == null) {
                                    await _service.addShippingCompany(
                                      name,
                                      cost,
                                    );
                                  } else {
                                    await _service.updateShippingCompany(
                                      company.id,
                                      name,
                                      cost,
                                    );
                                  }
                                  Navigator.pop(ctx);
                                  _fetchCompanies(); // تحديث القائمة
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("تم الحفظ بنجاح ✅"),
                                    ),
                                  );
                                } catch (e) {
                                  setDialogState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("خطأ: $e")),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF105C6),
                      ),
                      child:
                          isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "حفظ",
                                style: TextStyle(color: Colors.black),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  // حذف شركة
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف الشركة"),
            content: const Text("هل أنت متأكد من حذف شركة الشحن هذه؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.deleteShippingCompany(id);
                  _fetchCompanies();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("تم الحذف")));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFFF105C6),
        icon: const Icon(Icons.add),
        label: const Text("إضافة شركة"),
      ),
      body: Stack(
        children: [
          // الخلفية الجمالية
          Positioned(
            top: -50,
            right: -50,
            child: _blurCircle(Colors.blue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blurCircle(Colors.purple.withOpacity(0.15)),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                iconTheme: const IconThemeData(color: Colors.black),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // إحصائية بسيطة
                      _buildStatCard(
                        "عدد الشركات المضافة",
                        "${_companies.length}",
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_companies.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "لا توجد شركات شحن مضافة",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _companies.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (ctx, i) => _buildCompanyCard(_companies[i]),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(ShippingCompany company) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.indigo],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${company.shippingCost} ر.س",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showFormDialog(company: company),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(company.id),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
