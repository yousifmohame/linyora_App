import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../models/wallet_models.dart';

class ModelWalletScreen extends StatefulWidget {
  const ModelWalletScreen({Key? key}) : super(key: key);

  @override
  State<ModelWalletScreen> createState() => _ModelWalletScreenState();
}

class _ModelWalletScreenState extends State<ModelWalletScreen> {
  final WalletService _service = WalletService();
  
  ModelWallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showBalance = true;
  
  final TextEditingController _amountController = TextEditingController();

  // Colors
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getWallet(),
        _service.getTransactions(),
      ]);
      
      if (mounted) {
        setState(() {
          _wallet = results[0] as ModelWallet;
          _transactions = results[1] as List<Transaction>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPayout() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الحد الأدنى للسحب 50 ر.س")));
      return;
    }
    if (amount > (_wallet?.balance ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرصيد غير كافٍ")));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.requestPayout(amount);
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم طلب السحب بنجاح ✅"), backgroundColor: Colors.green));
      _fetchData(); // تحديث الرصيد
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل الطلب: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50.withOpacity(0.3), Colors.purple.shade50.withOpacity(0.3)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(top: -50, right: -50, child: _buildBlurBlob(Colors.pink.shade200)),
          Positioned(bottom: -50, left: -50, child: _buildBlurBlob(Colors.purple.shade200)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        "الرصيد المتاح", 
                        _showBalance ? "${_wallet?.balance} ر.س" : "••••", 
                        Icons.account_balance_wallet, 
                        Colors.green,
                        showToggle: true
                      ),
                      _buildStatCard("قيد المعالجة", "${_wallet?.pendingClearance} ر.س", Icons.hourglass_empty, Colors.amber),
                      _buildStatCard("إجمالي الأرباح", "${_wallet?.totalEarnings} ر.س", Icons.trending_up, Colors.blue),
                      _buildStatCard("سحوبات الشهر", "0.00 ر.س", Icons.history, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Payout Request Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.send, color: _purpleColor), const SizedBox(width: 8), const Text("طلب سحب أرباح", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "المبلغ (ر.س)",
                            hintText: "أدخلي المبلغ المطلوب",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: const Padding(padding: EdgeInsets.all(12), child: Text("ر.س", style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [100, 250, 500, 1000].map((amt) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ActionChip(
                              label: Text("$amt"),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              onPressed: () => _amountController.text = amt.toString(),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _requestPayout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _roseColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSubmitting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text("تأكيد الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Transactions List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: const Row(children: [Icon(Icons.history, color: Colors.white), SizedBox(width: 8), Text("سجل المعاملات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                        ),
                        if (_transactions.isEmpty)
                          const Padding(padding: EdgeInsets.all(30), child: Text("لا توجد معاملات سابقة", style: TextStyle(color: Colors.grey)))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) => _buildTransactionItem(_transactions[idx]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.account_balance_wallet, color: _roseColor, size: 28)),
            const SizedBox(width: 12),
            const Text("المحفظة", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        const Text("إدارة أرباحك وسحوباتك المالية", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool showToggle = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              if (showToggle)
                InkWell(
                  onTap: () => setState(() => _showBalance = !_showBalance),
                  child: Icon(_showBalance ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey),
                )
              else
                Icon(icon, size: 16, color: color),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    Color color = t.type == 'earning' ? Colors.green : Colors.red;
    String sign = t.type == 'earning' ? '+' : '-';
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(t.type == 'earning' ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
      ),
      title: Text(t.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(t.date)), style: const TextStyle(fontSize: 11)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("$sign${t.amount} ر.س", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
            child: Text(t.status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: Colors.transparent)),
    );
  }
}