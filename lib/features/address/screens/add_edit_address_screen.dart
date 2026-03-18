import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../providers/address_provider.dart';
import '../../../models/checkout_models.dart';
import 'osm_map_screen.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _address1Controller;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;

  double? _lat;
  double? _long;
  bool _isDefault = false;
  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFFF105C6);
  final Color _fillColor = const Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.address?.fullName ?? '',
    );
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _address1Controller = TextEditingController(
      text: widget.address?.addressLine1 ?? '',
    );

    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _zipController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );
    _countryController = TextEditingController(
      text: widget.address?.country ?? 'السعودية',
    );

    _lat = widget.address?.latitude;
    _long = widget.address?.longitude;

    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _address1Controller.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OsmMapScreen()),
    );

    if (result != null && result is LatLng) {
      if (!mounted) return;
      setState(() {
        _lat = result.latitude;
        _long = result.longitude;
      });
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _long == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectLocationWarning), // ✅ مترجم
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      "fullName": _nameController.text,
      "addressLine1": _address1Controller.text,
      "addressLine2": "",
      "city": _cityController.text,
      "state":
          _stateController.text.isEmpty
              ? "المنطقة الوسطى"
              : _stateController.text,
      "postalCode": _zipController.text.isEmpty ? "00000" : _zipController.text,
      "country": _countryController.text,
      "phoneNumber": _phoneController.text,
      "is_default": _isDefault ? 1 : 0,
      "latitude": _lat,
      "longitude": _long,
    };

    try {
      final provider = Provider.of<AddressProvider>(context, listen: false);
      if (widget.address == null) {
        await provider.addAddress(data);
      } else {
        await provider.updateAddress(widget.address!.id, data);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addressSavedSuccess), // ✅ مترجم
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = l10n.saveFailedMsg; // ✅ مترجم
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          final serverMsg = e.response?.data['message'];
          if (serverMsg != null) errorMessage = serverMsg;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.address == null
              ? l10n.addNewAddressTitle
              : l10n.editAddressTitle, // ✅ مترجم
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _save(l10n), // ✅ تمرير l10n
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      widget.address == null
                          ? l10n.saveAddressBtn
                          : l10n.updateDataBtn, // ✅ مترجم
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(l10n.deliveryLocationSection), // ✅ مترجم
              const SizedBox(height: 10),
              _buildMapSelector(l10n), // ✅ تمرير الترجمة

              const SizedBox(height: 25),

              _buildSectionTitle(l10n.recipientDataSection), // ✅ مترجم
              const SizedBox(height: 10),
              _buildModernTextField(
                controller: _nameController,
                label: l10n.fullNameLabel, // ✅ مترجم
                hint: l10n.fullNameHint, // ✅ مترجم
                icon: Icons.person_outline,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                controller: _phoneController,
                label: l10n.phoneNumberLabel, // ✅ مترجم
                hint: l10n.phoneHint, // ✅ مترجم
                icon: Icons.phone_android_outlined,
                isPhone: true,
                l10n: l10n,
              ),

              const SizedBox(height: 25),

              _buildSectionTitle(l10n.addressDetailsSection), // ✅ مترجم
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _countryController,
                      label: l10n.countryLabel, // ✅ مترجم
                      icon: Icons.flag_outlined,
                      readOnly: true,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _cityController,
                      label: l10n.cityLabel, // ✅ مترجم
                      icon: Icons.location_city_outlined,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _stateController,
                      label: l10n.regionDistrictLabel, // ✅ مترجم
                      icon: Icons.map_outlined,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _zipController,
                      label: l10n.postalCodeLabel, // ✅ مترجم
                      icon: Icons.markunread_mailbox_outlined,
                      isPhone: true,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildModernTextField(
                controller: _address1Controller,
                label: l10n.streetNameDescLabel, // ✅ مترجم
                hint: l10n.streetNameHint, // ✅ مترجم
                icon: Icons.home_outlined,
                maxLines: 2,
                l10n: l10n,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.setAsDefaultLabel, // ✅ مترجم
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    l10n.setAsDefaultDesc, // ✅ مترجم
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: _isDefault,
                  activeColor: _primaryColor,
                  onChanged: (val) => setState(() => _isDefault = val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMapSelector(AppLocalizations l10n) {
    bool isSelected = _lat != null;
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.green.withOpacity(0.05)
                  : const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : _primaryColor.withOpacity(0.3),
            width: 1.5,
            style: isSelected ? BorderStyle.solid : BorderStyle.none,
          ),
          image:
              isSelected
                  ? null
                  : const DecorationImage(
                    image: AssetImage('assets/images/map_placeholder.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.location_on_rounded,
              color: isSelected ? Colors.green : _primaryColor,
              size: 35,
            ),
            const SizedBox(height: 8),
            Text(
              isSelected
                  ? l10n.locationSelectedSuccess
                  : l10n.tapToSelectLocation, // ✅ مترجم
              style: TextStyle(
                color: isSelected ? Colors.green.shade700 : _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Text(
                "${l10n.coordinatesLabel}${_lat!.toStringAsFixed(4)}, ${_long!.toStringAsFixed(4)}", // ✅ مترجم
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
            else
              Text(
                l10n.locationRequiredDesc, // ✅ مترجم
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isPhone = false,
    bool readOnly = false,
    int maxLines = 1,
    required AppLocalizations l10n, // ✅ استقبال الترجمة
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500),
      validator: (val) {
        if (readOnly) return null;
        if (val == null || val.isEmpty) return l10n.requiredFieldMsg; // ✅ مترجم
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
        filled: true,
        fillColor: _fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
