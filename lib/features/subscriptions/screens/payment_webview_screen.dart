import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;

  const PaymentWebViewScreen({Key? key, required this.checkoutUrl}) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // إعداد الـ WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // ✅ هنا الذكاء: مراقبة الرابط لمعرفة حالة الدفع
            
            // 1. حالة النجاح (تأكد من الرابط الذي يرسله الباك إند عند النجاح)
            // عادة يحتوي على كلمة success أو thank-you
            if (request.url.contains('success') || request.url.contains('payment-confirmed')) {
              Navigator.pop(context, true); // نعود بـ true (تم الدفع)
              return NavigationDecision.prevent; // نوقف تحميل الصفحة لأننا سنخرج
            }

            // 2. حالة الإلغاء
            if (request.url.contains('cancel') || request.url.contains('failed')) {
              Navigator.pop(context, false); // نعود بـ false (فشل)
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الدفع الآمن", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context, false), // إغلاق واعتبار الدفع ملغى
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
            ),
        ],
      ),
    );
  }
}