import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  // 1. تعريف المتحكمات القديمة والجديدة
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _address1Controller;

  // ✨ المتحكمات الجديدة للحقول الناقصة في قاعدة البيانات
  late TextEditingController _stateController; // المنطقة
  late TextEditingController _zipController; // الرمز البريدي
  late TextEditingController _countryController; // الدولة

  double? _lat;
  double? _long;

  bool _isDefault = false;
  bool _isLoading = false;

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
    _isDefault = widget.address?.isDefault ?? false;

    // ✨ تهيئة الحقول الجديدة
    // ملاحظة: إذا لم يكن المودل يحتوي على هذه الحقول بعد، نتركها فارغة
    _stateController = TextEditingController(text: '');
    _zipController = TextEditingController(text: '');
    _countryController = TextEditingController(
      text: 'المملكة العربية السعودية',
    ); // قيمة افتراضية

    // إذا كنت تريد دعم التعديل لاحقاً، يجب تحديث AddressModel ليشمل هذه الحقول
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تحديد الموقع بنجاح!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _save() async {
    // 1. التحقق من الحقول
    if (!_formKey.currentState!.validate()) return;

    // التحقق من الخريطة
    if (_lat == null || _long == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء تحديد الموقع على الخريطة أولاً"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. تجهيز البيانات (تصحيح القيم لتناسب MySQL)
    final data = {
      // ✅ الحقول الإجبارية (كما هي في req.body)
      "fullName": _nameController.text,
      "addressLine1": _address1Controller.text,
      "addressLine2":
          "", // يمكن تركه فارغاً لأنه ليس في شرط التحقق، لكنه مطلوب في الإدخال
      "city": _cityController.text,
      "state":
          _stateController.text.isEmpty
              ? "المنطقة الوسطى"
              : _stateController.text,
      "postalCode": _zipController.text.isEmpty ? "00000" : _zipController.text,
      "country":
          _countryController.text.isEmpty
              ? "Saudi Arabia"
              : _countryController.text,
      "phoneNumber": _phoneController.text,

      // ✅ حقول إضافية (أرسلها حتى لو لم يستخدمها هذا الروت حالياً، قد يحتاجها Middleware آخر)
      "is_default": _isDefault ? 1 : 0,
      "latitude": _lat,
      "longitude": _long,
    };
    // طباعة البيانات المرسلة في الكونسول للمراجعة
    print("🚀 Sending Data: $data");

    try {
      final provider = Provider.of<AddressProvider>(context, listen: false);

      if (widget.address == null) {
        await provider.addAddress(data);
      } else {
        await provider.updateAddress(widget.address!.id, data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حفظ العنوان بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 3. كشف سبب الخطأ الحقيقي (400)
      String errorMessage = "فشل الحفظ: تأكد من صحة البيانات";

      if (e is DioException) {
        // طباعة رد السيرفر في الكونسول (مهم جداً!)
        print("❌ Server Error Status: ${e.response?.statusCode}");
        print("❌ Server Error Data: ${e.response?.data}");

        // محاولة استخراج رسالة الخطأ وعرضها للمستخدم
        if (e.response?.data != null && e.response?.data is Map) {
          final serverMsg =
              e.response?.data['message']; // أو 'error' حسب الباك إند
          if (serverMsg != null) {
            errorMessage = "خطأ: $serverMsg";
          }
        }
      } else {
        print("❌ General Error: $e");
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
          widget.address == null ? "إضافة عنوان جديد" : "تعديل العنوان",
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // الاسم والجوال
              _buildTextField("الاسم بالكامل", _nameController, Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                "رقم الجوال",
                _phoneController,
                Icons.phone,
                isPhone: true,
              ),
              const SizedBox(height: 16),

              // زر الخريطة
              _buildMapButton(),
              const SizedBox(height: 16),

              // الدولة (يمكن جعلها readonly إذا أردت تثبيتها)
              _buildTextField("الدولة", _countryController, Icons.flag),
              const SizedBox(height: 16),

              // ✨ صف المدينة والمنطقة
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "المدينة",
                      _cityController,
                      Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      "المنطقة",
                      _stateController,
                      Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✨ صف الرمز البريدي والعنوان
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الرمز البريدي (ثلث المساحة)
                  SizedBox(
                    width: 100,
                    child: _buildTextField(
                      "الرمز البريدي",
                      _zipController,
                      Icons.numbers,
                      isPhone: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // العنوان التفصيلي (باقي المساحة)
                  Expanded(
                    child: _buildTextField(
                      "العنوان (الحي، الشارع)",
                      _address1Controller,
                      Icons.home,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("تعيين كعنوان افتراضي"),
                value: _isDefault,
                activeColor: const Color(0xFFF105C6),
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                ? "حفظ العنوان"
                                : "تحديث العنوان",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت زر الخريطة (فصلته لترتيب الكود)
  Widget _buildMapButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color: (_lat == null) ? Colors.red.shade300 : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          _lat != null ? Icons.location_on : Icons.map,
          color: _lat != null ? const Color(0xFFF105C6) : Colors.grey,
        ),
        title: Text(
          _lat != null ? "تم تحديد الموقع" : "تحديد الموقع من الخريطة (مطلوب)",
          style: TextStyle(
            color: _lat != null ? const Color(0xFFF105C6) : Colors.red,
            fontWeight: _lat != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle:
            _lat != null
                ? Text(
                  "Lat: $_lat, Lng: $_long",
                  style: const TextStyle(fontSize: 12),
                )
                : const Text(
                  "يجب تحديد الموقع لتوصيل الطلب بدقة",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _pickLocation,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      validator: (val) => val!.isEmpty ? "مطلوب" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF105C6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }
}
