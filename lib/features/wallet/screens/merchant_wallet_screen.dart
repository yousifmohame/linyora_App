import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class MerchantWalletScreen extends StatefulWidget {
  const MerchantWalletScreen({Key? key}) : super(key: key);

  @override
  State<MerchantWalletScreen> createState() => _MerchantWalletScreenState();
}

class _MerchantWalletScreenState extends State<MerchantWalletScreen> with SingleTickerProviderStateMixin {
  final WalletService _service = WalletService();
  late TabController _tabController;

  WalletData? _wallet;
  List<WalletTransaction> _transactions = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final walletData = await _service.getWalletData();
      final transactionsData = await _service.getTransactions();
      
      if (mounted) {
        setState(() {
          _wallet = walletData;
          _transactions = transactionsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePayoutRequest() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final balance = _wallet?.balance ?? 0.0;

    // التحقق من المدخلات (Validations)
    if (amount <= 0) {
      _showSnackBar('يرجى إدخال مبلغ صحيح', isError: true);
      return;
    }
    if (amount > balance) {
      _showSnackBar('رصيدك غير كافٍ', isError: true);
      return;
    }
    if (amount < 50) {
      _showSnackBar('الحد الأدنى للسحب هو 50 ر.س', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await _service.requestPayout(amount);
      _showSnackBar(message, isError: false);
      _amountController.clear();
      _fetchData(); // تحديث البيانات
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd | hh:mm a').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFF3E8FF)], // Gradient background
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("المحفظة", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("إدارة أرباحك وسحب الرصيد", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: const Icon(Icons.account_balance_wallet, color: Color(0xFF9333EA)),
                    )
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  labelColor: const Color(0xFF9333EA),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "نظرة عامة", icon: Icon(Icons.dashboard_outlined, size: 18)),
                    Tab(text: "سجل المعاملات", icon: Icon(Icons.history, size: 18)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Overview
                          _buildOverviewTab(),
                          
                          // Tab 2: Transactions
                          _buildTransactionsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Overview Tab ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                "الرصيد المتاح",
                "${_wallet?.balance.toStringAsFixed(2) ?? 0} ر.س",
                Icons.attach_money,
                Colors.green,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                "قيد المراجعة",
                "${_wallet?.pendingClearance.toStringAsFixed(2) ?? 0} ر.س",
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            "إجمالي الأرباح",
            "${_wallet?.totalEarnings.toStringAsFixed(2) ?? 0} ر.س",
            Icons.trending_up,
            Colors.blue,
            isFullWidth: true,
          ),

          const SizedBox(height: 24),

          // Payout Request Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.send, color: Color(0xFF9333EA)),
                    SizedBox(width: 8),
                    Text("طلب سحب رصيد", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "الحد الأدنى للسحب هو 50.00 ر.س",
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "المبلغ المطلوب",
                          hintText: "0.00",
                          suffixText: "ر.س",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handlePayoutRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send),
                    ),
                  ],
                ),
                if (_amountController.text.isNotEmpty)
                   // ... يمكن إضافة تحقق لحظي هنا مثل React
                   const SizedBox()
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                _InfoRow(icon: Icons.security, title: "آمن ومحمي", desc: "جميع المعاملات مشفرة وآمنة."),
                SizedBox(height: 12),
                _InfoRow(icon: Icons.access_time, title: "وقت المعالجة", desc: "تتم معالجة الطلبات خلال 3-5 أيام عمل."),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Transactions Tab ---
  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("لا توجد معاملات سابقة", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trans = _transactions[index];
        final isPayout = trans.type == 'payout';
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPayout ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPayout ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPayout ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPayout ? "سحب رصيد" : (trans.type == 'earning' ? "ربح مبيعات" : "استرداد"),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      trans.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(trans.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPayout ? '-' : '+'}${trans.amount} ر.س",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isPayout ? Colors.red : Colors.green,
                      fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(trans.status),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 0 : 1,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = "مكتمل";
        break;
      case 'pending':
        color = Colors.orange;
        text = "معلق";
        break;
      case 'failed':
        color = Colors.red;
        text = "فشل";
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.purple.shade300),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }
}