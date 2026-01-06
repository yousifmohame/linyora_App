import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../../../models/payment_card_model.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<PaymentProvider>(context, listen: false).fetchCards()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "طرق الدفع",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cards.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cards.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final card = provider.cards[index];

              return Dismissible(
                key: Key(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  provider.deleteCard(card.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف البطاقة")),
                  );
                },
                // ✅ هنا الحل: نستخدم ودجت خفيف خاص بنا بدلاً من المكتبة
                child: _buildCustomCreditCard(card),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCardScreen()),
          );
        },
        backgroundColor: const Color(0xFFF105C6),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- تصميم البطاقة اليدوي (خفيف وسريع وبدون أخطاء) ---
  Widget _buildCustomCreditCard(PaymentCardModel card) {
    return Container(
      width: double.infinity,
      height: 200, // ارتفاع قياسي للبطاقة
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // لون البطاقة (أسود)
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2C2C),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الصف العلوي: الشريحة + اللوجو
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // رسم الشريحة الذهبية
              Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37), // ذهبي
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFEE184), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(painter: ChipPainter()), // تفاصيل الشريحة (اختياري)
              ),
              // اللوجو (نص أو أيقونة حسب النوع)
              _buildCardBrandIcon(card.brand),
            ],
          ),

          // رقم البطاقة
          Row(
            children: [
              const Text(
                "••••  ••••  ••••  ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              Text(
                card.last4,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Courier', // خط يشبه خط البطاقات
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // الصف السفلي: الاسم + التاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CARD HOLDER",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "CARD HOLDER", // يمكن وضع card.holderName هنا لو كان متوفراً
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "EXPIRES",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.expiryDateFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  // دالة لتحديد أيقونة نوع البطاقة
  Widget _buildCardBrandIcon(String brand) {
    IconData iconData = Icons.credit_card;
    Color color = Colors.white;

    if (brand.toLowerCase().contains('visa')) {
      return const Text(
        "VISA",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (brand.toLowerCase().contains('master')) {
      return Row(
        children: [
          Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          Transform.translate(
            offset: const Offset(-8, 0),
            child: Container(
              width: 20, 
              height: 20, 
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.8), shape: BoxShape.circle)
            ),
          ),
        ],
      );
    }

    return Icon(iconData, color: color, size: 30);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "لا توجد بطاقات محفوظة",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCardScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("إضافة بطاقة"),
          )
        ],
      ),
    );
  }
}

// رسم خطوط الشريحة لتبدو واقعية
class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // رسم خطوط تقريبية للشريحة
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(6)), paint);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}