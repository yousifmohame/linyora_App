import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/services/auth_service.dart'; // تأكد من المسار
import 'package:linyora_project/l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _imageFile; // الصورة الجديدة المختارة
  bool _isLoading = false;
  final AuthService _authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    // ملء البيانات الحالية
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? ''; // افترضنا وجود حقل للهاتف
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // دالة اختيار الصورة
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // ضغط الجودة (مهم جداً)
      maxWidth: 1024, // تصغير الأبعاد
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // دالة الحفظ
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء دالة التحديث في السيرفس (يجب إضافتها هناك)
      bool success = await _authService.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        imageFile: _imageFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
        );
        Navigator.pop(context); // العودة للصفحة السابقة
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التحديث، حاول مرة أخرى')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    // يمكن استبدال النصوص بـ l10n لاحقاً

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "تعديل الملف الشخصي",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- صورة البروفايل ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 10, color: Colors.black12),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        // 1. تحديد الصورة الخلفية (من الملف أو من الرابط)
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : (user?.avatar != null &&
                                    user!.avatar!.isNotEmpty) // أضفنا ! للتأكيد
                                ? CachedNetworkImageProvider(
                                  user!.avatar!,
                                ) // أضفنا ! هنا أيضاً
                                : null,
                        // 2. تحديد الأيقونة (تظهر فقط إذا لم تكن هناك صورة)
                        child:
                            (_imageFile == null &&
                                    (user?.avatar == null ||
                                        user!.avatar!.isEmpty))
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF105C6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- حقول الإدخال ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "الاسم الكامل",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (value) => value!.isEmpty ? "الرجاء إدخال الاسم" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف",
                  prefixIcon: const Icon(Icons.phone_iphone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- زر الحفظ ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF105C6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "حفظ التغييرات",
                            style: TextStyle(
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
}
