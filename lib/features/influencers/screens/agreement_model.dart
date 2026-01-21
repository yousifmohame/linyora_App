import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:linyora_project/features/models/services/content_service.dart';


class AgreementModal extends StatefulWidget {
  final String agreementKey;
  final VoidCallback onAgreed;

  const AgreementModal({
    Key? key,
    this.agreementKey = "model_agreement", // المفتاح الافتراضي كما في React
    required this.onAgreed,
  }) : super(key: key);

  @override
  State<AgreementModal> createState() => _AgreementModalState();
}

class _AgreementModalState extends State<AgreementModal> {
  final AgreementService _service = AgreementService();

  bool _isLoadingContent = true;
  bool _isSubmitting = false;
  String _title = "";
  String _content = "";
  bool _hasError = false;

  // ألوان Rose Theme (مطابقة للموقع)
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose900 = Color(0xFF881337);

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  // جلب المحتوى الحقيقي من السيرفر
  Future<void> _fetchContent() async {
    try {
      final data = await _service.getAgreementContent(widget.agreementKey);
      if (mounted) {
        setState(() {
          _title = data['title'] ?? "الاتفاقية";
          _content = data['content'] ?? ""; // هنا يأتي كود HTML
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  // الموافقة
  Future<void> _handleAgree() async {
    setState(() => _isSubmitting = true);
    try {
      await _service.acceptAgreement();
      if (mounted) {
        widget.onAgreed(); // تبليغ الشاشة الرئيسية
        Navigator.pop(context); // إغلاق النافذة

        // رسالة نجاح (Toast البديل)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ شكرًا لموافقتك على الشروط والأحكام'),
            backgroundColor: rose500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope يمنع إغلاق النافذة (إجباري مثل الموقع)
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: rose200, width: 2),
            boxShadow: [
              BoxShadow(
                color: rose500.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            children: [
              // --- Header ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: rose50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: rose200),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: rose500,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.auto_awesome,
                          color: rose200,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLoadingContent ? "جاري التحميل..." : _title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rose900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // --- Content (HTML) ---
              Expanded(
                child:
                    _hasError
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              const Text("فشل تحميل الاتفاقية"),
                              TextButton(
                                onPressed: _fetchContent,
                                child: const Text("إعادة المحاولة"),
                              ),
                            ],
                          ),
                        )
                        : _isLoadingContent
                        ? const Center(
                          child: CircularProgressIndicator(color: rose500),
                        )
                        : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          // مكتبة HTML Rendering
                          child: HtmlWidget(
                            _content,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                              fontFamily: 'Cairo', // تأكد من وجود الخط
                            ),
                            // تنسيق العناوين داخل HTML لتشبه Rose Theme
                            customStylesBuilder: (element) {
                              if (element.localName == 'h1')
                                return {
                                  'color': '#881337',
                                  'font-weight': 'bold',
                                };
                              if (element.localName == 'h2')
                                return {
                                  'color': '#be123c',
                                  'font-weight': '600',
                                };
                              if (element.localName == 'strong')
                                return {'color': '#e11d48'};
                              return null;
                            },
                          ),
                        ),
              ),

              // --- Footer ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: rose200)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoadingContent || _isSubmitting || _hasError)
                            ? null
                            : _handleAgree,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rose500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: rose500.withOpacity(0.4),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "أوافق على الشروط",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
