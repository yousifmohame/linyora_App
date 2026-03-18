import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../models/shipping_company_model.dart';
import '../services/shipping_service.dart';

class MerchantShippingScreen extends StatefulWidget {
  const MerchantShippingScreen({Key? key}) : super(key: key);

  @override
  State<MerchantShippingScreen> createState() => _MerchantShippingScreenState();
}

class _MerchantShippingScreenState extends State<MerchantShippingScreen> {
  final ShippingService _service = ShippingService();

  List<ShippingCompany> _allCompanies = [];
  List<ShippingCompany> _filteredCompanies = [];

  bool _isLoading = true;
  String _searchTerm = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  // ✅ تمرير l10n
  Future<void> _fetchCompanies({AppLocalizations? l10n}) async {
    setState(() => _isLoading = true);
    try {
      final companies = await _service.getCompanies();
      if (mounted) {
        setState(() {
          _allCompanies = companies;
          _filterCompanies();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (l10n != null)
        _showSnackBar(l10n.failedToLoadDataMsg, isError: true); // ✅ مترجم
    }
  }

  void _filterCompanies() {
    setState(() {
      _filteredCompanies =
          _allCompanies.where((c) {
            return c.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                c.deliveryTime.toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                );
          }).toList();
    });
  }

  // ✅ تمرير l10n
  Future<void> _handleSave(AppLocalizations l10n, {int? id}) async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'shipping_cost': double.parse(_costController.text),
        'delivery_time':
            _timeController.text.isEmpty ? '3-5 أيام' : _timeController.text,
        'is_active': true,
      };

      if (id != null) {
        await _service.updateCompany(id, data);
        _showSnackBar(l10n.dataUpdatedSuccessfullyMsg); // ✅ مترجم
      } else {
        await _service.createCompany(data);
        _showSnackBar(l10n.companyAddedSuccessfullyMsg); // ✅ مترجم
      }
      _fetchCompanies();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(l10n.errorWhileSavingMsg, isError: true); // ✅ مترجم
    }
  }

  // ✅ تمرير l10n
  Future<void> _handleDelete(int id, AppLocalizations l10n) async {
    try {
      await _service.deleteCompany(id);
      _showSnackBar(l10n.deletedSuccessfullyMsg); // ✅ مترجم
      _fetchCompanies();
    } catch (e) {
      _showSnackBar(l10n.deletionFailedMsg, isError: true); // ✅ مترجم
    }
  }

  // ✅ تمرير l10n
  Future<void> _handleStatusToggle(
    ShippingCompany company,
    AppLocalizations l10n,
  ) async {
    setState(() {
      final index = _allCompanies.indexWhere((c) => c.id == company.id);
      if (index != -1) {}
    });

    try {
      await _service.toggleStatus(company.id, !company.isActive);
      _showSnackBar(
        company.isActive ? l10n.companyDisabledMsg : l10n.companyEnabledMsg,
      ); // ✅ مترجم
      _fetchCompanies();
    } catch (e) {
      _showSnackBar(l10n.statusChangeFailedMsg, isError: true); // ✅ مترجم
    }
  }

  void _showAddEditDialog(AppLocalizations l10n, {ShippingCompany? company}) {
    _nameController.text = company?.name ?? '';
    _costController.text = company?.shippingCost.toString() ?? '';
    _timeController.text = company?.deliveryTime ?? '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.local_shipping, color: Color(0xFF9333EA)),
                const SizedBox(width: 8),
                Text(
                  company == null
                      ? l10n.addNewCompanyTitle
                      : l10n.editDataTitle,
                ), // ✅ مترجم
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      l10n.companyNameLabel,
                      Icons.business,
                    ), // ✅ مترجم
                    validator:
                        (v) =>
                            v!.isEmpty ? l10n.requiredField : null, // ✅ مترجم
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _costController,
                    decoration: _inputDecoration(
                      '${l10n.shippingCostLabel} (${l10n.currencySAR})',
                      Icons.attach_money,
                    ), // ✅ مترجم وعملة
                    keyboardType: TextInputType.number,
                    validator:
                        (v) =>
                            v!.isEmpty ? l10n.requiredField : null, // ✅ مترجم
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _timeController,
                    decoration: _inputDecoration(
                      l10n.deliveryTimeLabel,
                      Icons.timer,
                    ), // ✅ مترجم
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancelBtn,
                  style: const TextStyle(color: Colors.grey),
                ), // ✅ مترجم
              ),
              ElevatedButton(
                onPressed:
                    () => _handleSave(l10n, id: company?.id), // ✅ تمرير l10n
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  company == null ? l10n.addBtn : l10n.saveChangesBtn,
                ), // ✅ مترجم
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirm(int id, String name, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.confirmDeletionTitle), // ✅ مترجم
            // ✅ صحيح
            content: Text(l10n.confirmDeleteCompanyDesc(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.backBtn), // ✅ مترجم
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleDelete(id, l10n); // ✅ تمرير l10n
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete), // ✅ مترجم
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    final int total = _allCompanies.length;
    final int active = _allCompanies.where((c) => c.isActive).length;
    final double totalCost = _allCompanies.fold(
      0,
      (sum, item) => sum + item.shippingCost,
    );
    final double avgCost = total > 0 ? totalCost / total : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFF3E8FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(l10n), // ✅ تمرير l10n
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatCard(
                          total.toString(),
                          l10n.totalStat,
                          Colors.pink,
                        ), // ✅ مترجم
                        const SizedBox(width: 8),
                        _buildStatCard(
                          active.toString(),
                          l10n.activeStat,
                          Colors.green,
                        ), // ✅ مترجم
                        const SizedBox(width: 8),
                        _buildStatCard(
                          avgCost.toStringAsFixed(0),
                          l10n.averagePriceStat,
                          Colors.blue,
                        ), // ✅ مترجم
                        const SizedBox(width: 8),
                        _buildStatCard(
                          totalCost.toStringAsFixed(0),
                          l10n.totalCostStat,
                          Colors.purple,
                        ), // ✅ مترجم
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            _searchTerm = val;
                            _filterCompanies();
                          },
                          decoration: InputDecoration(
                            hintText: "${l10n.searchBtn}...", // ✅ مترجم
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _fetchCompanies(l10n: l10n),
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        tooltip: l10n.refreshTooltip, // ✅ مترجم
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            () => _showAddEditDialog(l10n), // ✅ تمرير l10n
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addBtn), // ✅ مترجم
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF43F5E),
                          ),
                        )
                        : _filteredCompanies.isEmpty
                        ? _buildEmptyState(l10n) // ✅ تمرير l10n
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _filteredCompanies.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildCompanyCard(
                              _filteredCompanies[index],
                              l10n,
                            ); // ✅ تمرير l10n
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: const Icon(Icons.local_shipping, color: Color(0xFFE11D48)),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.shippingManagementTitle, // ✅ مترجم
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.manageShippingCompaniesDesc, // ✅ مترجم
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade100),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(ShippingCompany company, AppLocalizations l10n) {
    String langCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _infoBadge(
                          Icons.attach_money,
                          "${company.shippingCost} ${l10n.currencySAR}",
                        ), // ✅ عملة مترجمة
                        const SizedBox(width: 8),
                        _infoBadge(Icons.timer, company.deliveryTime),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed:
                            () => _showAddEditDialog(
                              l10n,
                              company: company,
                            ), // ✅ تمرير l10n
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed:
                            () => _showDeleteConfirm(
                              company.id,
                              company.name,
                              l10n,
                            ), // ✅ تمرير l10n
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${l10n.addedOnPrefix}${DateFormat('yyyy-MM-dd', langCode).format(DateTime.parse(company.createdAt))}", // ✅ مترجم
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Row(
                children: [
                  Switch(
                    value: company.isActive,
                    activeColor: Colors.green,
                    onChanged:
                        (val) =>
                            _handleStatusToggle(company, l10n), // ✅ تمرير l10n
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          company.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            company.isActive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      company.isActive
                          ? l10n.activeStatus
                          : l10n.inactiveStatus, // ✅ مترجم
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            company.isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noShippingCompaniesMsg,
            style: const TextStyle(color: Colors.grey),
          ), // ✅ مترجم
          if (_searchTerm.isNotEmpty)
            Text(
              l10n.trySearchingOtherWordMsg,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ), // ✅ مترجم
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
