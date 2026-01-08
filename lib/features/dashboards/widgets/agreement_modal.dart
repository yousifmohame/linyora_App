import 'package:flutter/material.dart';
import '../services/merchant_service.dart';

class AgreementModal extends StatefulWidget {
  final VoidCallback onAgreed;

  const AgreementModal({Key? key, required this.onAgreed}) : super(key: key);

  @override
  State<AgreementModal> createState() => _AgreementModalState();
}

class _AgreementModalState extends State<AgreementModal> {
  bool _isLoading = false;
  final MerchantService _merchantService = MerchantService();

  Future<void> _handleAgree() async {
    setState(() => _isLoading = true);
    try {
      await _merchantService.acceptAgreement();
      
      // ✅ التحقق من mounted قبل استخدام context أو widget
      if (!mounted) return;
      
      widget.onAgreed(); // تحديث الحالة في الشاشة الرئيسية
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الموافقة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // منع إغلاق النافذة بالرجوع للخلف
      child: AlertDialog(
        title: const Text('اتفاقية التاجر'),
        content: const SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'مرحباً بك في منصة التجار. يرجى قراءة والموافقة على الشروط والأحكام للمتابعة.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              // يمكنك إضافة رابط للشروط هنا
              Text(
                'بموافقتك، أنت تلتزم بجميع سياسات البيع والخصوصية...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAgree,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA), // Purple
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('أوافق وأتابع'),
            ),
          ),
        ],
      ),
    );
  }
}