import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لإضافة اهتزاز خفيف عند الضغط
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
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

  // Controllers
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

  // الألوان المستخدمة
  final Color _primaryColor = const Color(0xFFF105C6);
  final Color _fillColor = const Color(0xFFF5F6FA); // لون خلفية الحقول

  @override
  void initState() {
    super.initState();
    
    // 1. ربط البيانات القديمة (الاسم، الجوال، المدينة، العنوان)
    _nameController = TextEditingController(text: widget.address?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _address1Controller = TextEditingController(text: widget.address?.addressLine1 ?? '');
    
    // 2. ✅✅✅ التصحيح هنا: ربط الحقول الجديدة (المنطقة، الرمز البريدي)
    // بدلاً من text: '' نضع القيمة القادمة من المودل
    _stateController = TextEditingController(text: widget.address?.state ?? ''); 
    _zipController = TextEditingController(text: widget.address?.postalCode ?? ''); 
    _countryController = TextEditingController(text: widget.address?.country ?? 'السعودية');
    
    // 3. ✅✅✅ التصحيح هنا: ربط الإحداثيات
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
    HapticFeedback.mediumImpact(); // تأثير اهتزاز خفيف
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _long == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ الرجاء تحديد موقع التوصيل على الخريطة"),
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
        const SnackBar(
          content: Text("✅ تم حفظ العنوان بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = "فشل الحفظ";
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.address == null ? "عنوان جديد" : "تعديل العنوان",
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
      // جعل الزر عائماً في الأسفل لضمان سهولة الوصول
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
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, // استخدام اللون الرئيسي للتطبيق
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
                      widget.address == null ? "حفظ العنوان" : "تحديث البيانات",
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
              // 1. قسم الخريطة (الأهم للتوصيل)
              _buildSectionTitle("موقع التوصيل"),
              const SizedBox(height: 10),
              _buildMapSelector(),

              const SizedBox(height: 25),

              // 2. معلومات الاتصال
              _buildSectionTitle("بيانات المستلم"),
              const SizedBox(height: 10),
              _buildModernTextField(
                controller: _nameController,
                label: "الاسم الكامل",
                hint: "مثال: محمد أحمد",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                controller: _phoneController,
                label: "رقم الجوال",
                hint: "05xxxxxxxx",
                icon: Icons.phone_android_outlined,
                isPhone: true,
              ),

              const SizedBox(height: 25),

              // 3. تفاصيل العنوان
              _buildSectionTitle("تفاصيل العنوان"),
              const SizedBox(height: 10),

              // سطر الدولة والمدينة
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _countryController,
                      label: "الدولة",
                      icon: Icons.flag_outlined,
                      readOnly: true, // عادة الدولة ثابتة
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _cityController,
                      label: "المدينة",
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // سطر المنطقة والرمز البريدي
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _stateController,
                      label: "المنطقة / الحي",
                      icon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _zipController,
                      label: "الرمز البريدي",
                      icon: Icons.markunread_mailbox_outlined,
                      isPhone: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // تفاصيل الشارع
              _buildModernTextField(
                controller: _address1Controller,
                label: "اسم الشارع / وصف المنزل",
                hint: "مثال: بجوار مسجد...",
                icon: Icons.home_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // 4. خيار الافتراضي
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
                  title: const Text(
                    "تعيين كعنوان افتراضي",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    "سيتم استخدام هذا العنوان تلقائياً للطلبات القادمة",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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

  // --- Widgets ---

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

  Widget _buildMapSelector() {
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
                  : const Color(0xFFFFF0F5), // لون خلفية خفيف
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : _primaryColor.withOpacity(0.3),
            width: 1.5,
            style:
                isSelected
                    ? BorderStyle.solid
                    : BorderStyle.none, // حدود متقطعة أو متصلة
          ),
          image:
              isSelected
                  ? null
                  : const DecorationImage(
                    // يمكنك وضع صورة خريطة ثابتة هنا كخلفية لزيادة الجمالية
                    image: AssetImage(
                      'assets/images/map_placeholder.png',
                    ), // تأكد من وجود صورة أو احذف السطر
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
                  ? "تم تحديد الموقع بنجاح"
                  : "اضغط لتحديد الموقع على الخريطة",
              style: TextStyle(
                color: isSelected ? Colors.green.shade700 : _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Text(
                "إحداثيات: ${_lat!.toStringAsFixed(4)}, ${_long!.toStringAsFixed(4)}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
            else
              const Text(
                "خطوة ضرورية لتوصيل الطلب لباب منزلك",
                style: TextStyle(color: Colors.grey, fontSize: 11),
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
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500),
      validator: (val) {
        if (readOnly) return null;
        if (val == null || val.isEmpty) return "هذا الحقل مطلوب";
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
          borderSide: BorderSide.none, // بدون حدود افتراضياً
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
