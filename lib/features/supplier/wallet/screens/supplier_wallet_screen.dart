import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/supplier/wallet/models/supplier_wallet_models.dart';
import 'package:linyora_project/features/supplier/wallet/services/supplier_wallet_service.dart';

class SupplierWalletScreen extends StatefulWidget {
  const SupplierWalletScreen({Key? key}) : super(key: key);

  @override
  State<SupplierWalletScreen> createState() => _SupplierWalletScreenState();
}

class _SupplierWalletScreenState extends State<SupplierWalletScreen> {
  final SupplierWalletService _service = SupplierWalletService();

  SupplierWallet? _walletData;
  List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // دمج جلب الرصيد والمعاملات
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getWalletData(),
        _service.getTransactions(),
      ]);

      if (mounted) {
        setState(() {
          _walletData = results[0] as SupplierWallet;
          _transactions = results[1] as List<WalletTransaction>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل تحميل البيانات")));
      }
    }
  }

  Future<void> _submitPayout() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى إدخال مبلغ صحيح")));
      return;
    }

    // التحقق من الرصيد
    if (_walletData != null && amount > _walletData!.balance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("رصيدك غير كافٍ")));
      return;
    }

    if (amount < 50) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("الحد الأدنى للسحب 50 ر.س")));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.requestPayout(amount);
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إرسال الطلب بنجاح ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // إغلاق النافذة المنبثقة إذا كانت مفتوحة
        _fetchAllData(); // تحديث البيانات
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ الحل الجذري للخطأ: التحقق قبل العرض
    if (_isLoading || _walletData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
                title: const Text(
                  "المحفظة",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                iconTheme: const IconThemeData(color: Colors.black),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1. بطاقات الرصيد
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalanceCard(
                              "الرصيد المتاح",
                              _walletData!.balance,
                              Icons.account_balance_wallet,
                              [Colors.green.shade400, Colors.teal.shade600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBalanceCard(
                              "أرباح معلقة",
                              _walletData!.pendingClearance,
                              Icons.hourglass_empty,
                              [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade600,
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. نموذج طلب السحب
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.05),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.monetization_on, color: Colors.blue),
                                SizedBox(width: 10),
                                Text(
                                  "طلب سحب رصيد",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: "المبلغ المراد سحبه",
                                suffixText: "ر.س",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _submitPayout,
                                icon:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.send),
                                label: const Text(
                                  "إرسال الطلب",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF105C6),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. سجل المعاملات
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "سجل المعاملات",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            "لا توجد معاملات سابقة",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (ctx, i) =>
                                  _buildTransactionTile(_transactions[i]),
                        ),

                      const SizedBox(height: 50),
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

  Widget _buildBalanceCard(
    String title,
    double amount,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Icon(icon, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${amount.toStringAsFixed(2)} ر.س",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction t) {
    final isPayout = t.type == 'payout';
    String formattedDate = t.date.split('T')[0]; // تنسيق بسيط للتاريخ

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isPayout
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPayout ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPayout ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isPayout ? '-' : '+'}${t.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPayout ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusText(t.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(String status) {
    Color color;
    String text;

    switch (status) {
      case 'completed':
      case 'paid':
      case 'cleared':
        color = Colors.green;
        text = "مكتمل";
        break;
      case 'rejected':
      case 'failed':
        color = Colors.red;
        text = "مرفوض";
        break;
      default:
        color = Colors.amber;
        text = "قيد المعالجة";
    }

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
