import 'package:flutter/material.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  // ✅ تمرير l10n للديالوج والرسائل
  void _showFormDialog(AppLocalizations l10n, {ShippingCompany? company}) {
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
                    company == null
                        ? l10n.addShippingCompanyTitle
                        : l10n.editShippingCompanyTitle,
                  ), // ✅ مترجم
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.companyNameLabel,
                          border: const OutlineInputBorder(),
                        ), // ✅ مترجم
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.shippingCostLabel,
                          border: const OutlineInputBorder(),
                        ), // ✅ مترجم
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancelBtn), // ✅ مترجم
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
                                    SnackBar(
                                      content: Text(l10n.enterValidDataMsg),
                                    ), // ✅ مترجم
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
                                  _fetchCompanies();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${l10n.savedSuccessfullyMsg} ✅",
                                      ),
                                    ), // ✅ مترجم
                                  );
                                } catch (e) {
                                  setDialogState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.errorOccurredWithErrorMsg(
                                          e.toString(),
                                        ),
                                      ),
                                    ), // ✅ استخدام الدالة المولدة بدل replaceAll
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
                              : Text(
                                l10n.saveBtn,
                                style: const TextStyle(color: Colors.black),
                              ), // ✅ مترجم
                    ),
                  ],
                ),
          ),
    );
  }

  // ✅ تمرير l10n لرسائل التأكيد
  void _confirmDelete(int id, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteCompanyTitle), // ✅ مترجم
            content: Text(l10n.confirmDeleteShippingCompanyDesc), // ✅ مترجم
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancelBtn), // ✅ مترجم
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.deleteShippingCompany(id);
                  _fetchCompanies();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.deletedSuccessfullyMsg)),
                  ); // ✅ مترجم (سابقاً)
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.white),
                ), // ✅ مترجم
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(l10n), // ✅ تمرير الترجمة
        backgroundColor: const Color(0xFFF105C6),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCompanyBtn), // ✅ مترجم
      ),
      body: Stack(
        children: [
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
                title: Text(
                  l10n.shippingCompanies,
                  style: const TextStyle(color: Colors.black),
                ), // ✅ عنوان اختياري (مترجم)
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatCard(
                        l10n.numberOfAddedCompanies,
                        "${_companies.length}",
                      ), // ✅ مترجم
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_companies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.noShippingCompaniesAddedMsg,
                                style: const TextStyle(color: Colors.grey),
                              ), // ✅ مترجم
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
                              (ctx, i) => _buildCompanyCard(
                                _companies[i],
                                l10n,
                              ), // ✅ تمرير l10n
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

  Widget _buildCompanyCard(ShippingCompany company, AppLocalizations l10n) {
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
                  "${company.shippingCost} ${l10n.currencySAR}", // ✅ مترجم (عملة)
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
            onPressed:
                () => _showFormDialog(l10n, company: company), // ✅ تمرير l10n
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(company.id, l10n), // ✅ تمرير l10n
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
