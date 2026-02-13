import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _service = WalletService();
  late TabController
  _tabController; // للتحكم في الفلترة (الكل، إيداع، خصم، سحب)

  WalletData? _wallet;
  List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _amountController = TextEditingController();

  // متغيرات العرض المحسوبة
  double get _displayAvailableBalance =>
      (_wallet?.balance ?? 0) > 0 ? (_wallet?.balance ?? 0) : 0.0;

  double get _displayTotalDebt {
    double rawBalance = _wallet?.balance ?? 0;
    double outstanding = _wallet?.outstandingDebt ?? 0;
    // الدين = المديونية المسجلة + العجز في الرصيد الرئيسي (إذا كان بالسالب)
    return outstanding + (rawBalance < 0 ? rawBalance.abs() : 0);
  }

  @override
  void initState() {
    super.initState();
    // 4 تابات: الكل، إيداعات، خصومات، سحوبات
    _tabController = TabController(length: 4, vsync: this);
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
      // يمكن إضافة SnackBar للخطأ هنا
    }
  }

  Future<void> _handlePayoutRequest() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      _showSnackBar('يرجى إدخال مبلغ صحيح', isError: true);
      return;
    }
    if (amount > _displayAvailableBalance) {
      _showSnackBar('رصيدك المتاح غير كافٍ', isError: true);
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
      Navigator.pop(context); // إغلاق الـ BottomSheet
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

  // ترجمة أنواع المعاملات للعربية
  String _translateType(String type) {
    switch (type) {
      case 'sale_earning':
        return 'أرباح مبيعات';
      case 'shipping_earning':
        return 'عائد شحن';
      case 'cod_commission_deduction':
        return 'عمولة (COD)';
      case 'commission_deduction':
        return 'خصم عمولة';
      case 'payout':
        return 'سحب رصيد';
      case 'agreement_income':
        return 'أرباح تسويق';
      case 'adjustment':
        return 'تسوية إدارية';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "المحفظة المالية",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildStatsGrid(),

                      const SizedBox(height: 16),

                      // زر السحب
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _displayAvailableBalance >= 50
                                    ? () => _showPayoutSheet()
                                    : null,
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text("طلب سحب رصيد"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // قسم المعاملات مع التابات
                      _buildTransactionsSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  // --- 1. شبكة البطاقات (4 Cards Grid) ---
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // البطاقة الخضراء: الرصيد المتاح
              Expanded(
                child: _buildStatCard(
                  title: "المتاح للسحب",
                  value: _displayAvailableBalance,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  subtext: "جاهز للتحويل",
                ),
              ),
              const SizedBox(width: 12),
              // البطاقة الحمراء: المديونيات (تظهر حتى لو 0 ولكن بتصميم مختلف)
              Expanded(
                child: _buildStatCard(
                  title: "المديونيات",
                  value: _displayTotalDebt,
                  icon: Icons.warning_amber_rounded,
                  color: _displayTotalDebt > 0 ? Colors.red : Colors.grey,
                  subtext:
                      _displayTotalDebt > 0
                          ? "يتم خصمها تلقائياً"
                          : "لا توجد مديونيات",
                  isDebt: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // البطاقة البرتقالية: المعلق
              Expanded(
                child: _buildStatCard(
                  title: "قيد التسوية",
                  value: _wallet?.pendingBalance ?? 0,
                  icon: Icons.access_time,
                  color: Colors.orange,
                  subtext: "${_wallet?.pendingTransactionsCount ?? 0} عمليات",
                ),
              ),
              const SizedBox(width: 12),
              // البطاقة الزرقاء: الإجمالي
              Expanded(
                child: _buildStatCard(
                  title: "إجمالي الأرباح",
                  value: _wallet?.totalEarnings ?? 0,
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  subtext: "التاريخي",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required String subtext,
    bool isDebt = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${NumberFormat('#,##0.00').format(value)} ر.س",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDebt && value > 0 ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ],
      ),
    );
  }

  // --- 2. قسم المعاملات مع التصفية ---
  Widget _buildTransactionsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF9333EA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF9333EA),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "الكل"),
              Tab(text: "إيداع"),
              Tab(text: "خصم"),
              Tab(text: "سحب"),
            ],
          ),
          SizedBox(
            height: 500, // ارتفاع ثابت للقائمة
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('all'),
                _buildTransactionList('earnings'),
                _buildTransactionList('deductions'),
                _buildTransactionList('payouts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String filterType) {
    // تصفية القائمة
    final filteredList =
        _transactions.where((t) {
          if (filterType == 'all') return true;
          if (filterType == 'earnings') return t.amount > 0;
          if (filterType == 'deductions')
            return t.amount < 0 && t.type != 'payout';
          if (filterType == 'payouts') return t.type == 'payout';
          return true;
        }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("لا توجد عمليات", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final trans = filteredList[index];
        final isPositive = trans.amount > 0;
        final isPayout = trans.type == 'payout';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isPayout
                          ? Colors.blue.shade50
                          : (isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPayout
                      ? Icons.arrow_outward
                      : (isPositive ? Icons.arrow_downward : Icons.remove),
                  color:
                      isPayout
                          ? Colors.blue
                          : (isPositive ? Colors.green : Colors.red),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateType(trans.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trans.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.parse(trans.createdAt)),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                        if (trans.referenceId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "#${trans.referenceId}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // المبلغ والحالة
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPositive ? '+' : ''}${trans.amount} ر.س",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(trans.status),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'cleared':
        color = Colors.green;
        text = "مكتمل";
        break;
      case 'pending':
        color = Colors.orange;
        text = "معلق";
        break;
      case 'processing':
        color = Colors.blue;
        text = "قيد المعالجة";
        break;
      case 'cancelled':
        color = Colors.red;
        text = "ملغي";
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
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Bottom Sheet للسحب ---
  void _showPayoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "طلب سحب أرباح",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "الرصيد المتاح: ${_displayAvailableBalance} ر.س",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "المبلغ المطلوب",
                    suffixText: "ر.س",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handlePayoutRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                            : const Text("تأكيد السحب"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
