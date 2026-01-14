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
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final data = await _service.getWalletData();
      if (mounted)
        setState(() {
          _walletData = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

    if (amount > (_walletData?.balance ?? 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("رصيدك غير كافٍ")));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.requestPayout(amount);
      _amountController.clear();
      _fetchWalletData(); // تحديث البيانات
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم إرسال الطلب بنجاح ✅")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ: ${e.toString().replaceAll('Exception: ', '')}"),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          // الخلفية
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
                              keyboardType: TextInputType.numberWithOptions(
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
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.amber.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "يتم تحويل المبالغ خلال 24-48 ساعة عمل.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. سجل عمليات السحب
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "سجل عمليات السحب",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_walletData!.payouts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            "لا توجد عمليات سحب سابقة",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _walletData!.payouts.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 12),
                          itemBuilder:
                              (ctx, i) =>
                                  _buildPayoutTile(_walletData!.payouts[i]),
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

  Widget _buildPayoutTile(PayoutRequest payout) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${payout.amount.toStringAsFixed(2)} ر.س",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat(
                  'yyyy/MM/dd',
                ).format(DateTime.parse(payout.createdAt)),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          _buildStatusBadge(payout.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = "مقبول";
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = "مرفوض";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.amber;
        text = "قيد المعالجة";
        icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
